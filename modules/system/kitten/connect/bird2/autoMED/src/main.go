package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/signal" // New import
	"sync"
	"syscall" // New import
	"time"

	"github.com/vishvananda/netlink"
)

// --- Configuration & Constants ---

const (
	maxSamples      = 100
	defaultInterval = time.Second
	recapInterval   = 10 * time.Second
	bgpInterval     = 1 * time.Minute
)

// --- Domain 2: Peer Detection ---

type MonitoredPeer struct {
	TargetIP  string
	Interface string
}

// --- Updated PeerDetector ---

type PeerDetector struct{}

func (pd *PeerDetector) Discover() ([]MonitoredPeer, error) {
	var peers []MonitoredPeer
	links, err := netlink.LinkList()
	if err != nil {
		return nil, err
	}

	for _, link := range links {
		addrs, _ := netlink.AddrList(link, netlink.FAMILY_V6)
		for _, addr := range addrs {
			ones, bits := addr.Mask.Size()
			// Filtering for /127 point-to-point links
			if ones == 127 && bits == 128 && addr.IP.IsGlobalUnicast() {
				peerIP := pd.calculatePeerIP(addr.IP)
				peers = append(peers, MonitoredPeer{
					TargetIP:  peerIP.String(),
					Interface: link.Attrs().Name,
				})
			}
		}
	}
	return peers, nil
}

func (pd *PeerDetector) calculatePeerIP(ip net.IP) net.IP {
	peer := make(net.IP, len(ip))
	copy(peer, ip)
	if peer[15]%2 == 0 {
		peer[15]++
	} else {
		peer[15]--
	}
	return peer
}

// --- Updated App Orchestrator ---

type App struct {
	Monitor  *LatencyMonitor
	Detector *PeerDetector
	Exporter *BGPExporter

	mu     sync.RWMutex // Protects the Peers slice and active cancel funcs
	Peers  []MonitoredPeer
	active map[string]context.CancelFunc
}

func NewApp(m *LatencyMonitor, d *PeerDetector, e *BGPExporter) *App {
	return &App{
		Monitor:  m,
		Detector: d,
		Exporter: e,
		active:   make(map[string]context.CancelFunc),
	}
}

func (a *App) Start(ctx context.Context) {
	// Initial discovery
	a.ReloadPeers(ctx)

	// 1. Listen for SIGHUP
	go a.listenForSignals(ctx)

	// 2. Ticker: Write BGP Config
	go func() {
		t := time.NewTicker(bgpInterval)
		for {
			select {
			case <-t.C:
				a.mu.RLock()
				a.Exporter.Export(a.Peers, a.Monitor)
				a.mu.RUnlock()
			case <-ctx.Done():
				return
			}
		}
	}()

	// 3. Ticker: Print Console Recap
	go func() {
		t := time.NewTicker(recapInterval)
		for {
			select {
			case <-t.C:
				a.printSummary()
			case <-ctx.Done():
				return
			}
		}
	}()

	<-ctx.Done() // Keep main alive until context canceled
}

func (a *App) listenForSignals(ctx context.Context) {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGHUP)

	for {
		select {
		case sig := <-sigChan:
			fmt.Fprintf(os.Stderr, "\n[%s] Signal received: %v. Triggering re-discovery...\n", time.Now().Format("15:04:05"), sig)
			a.ReloadPeers(ctx)
		case <-ctx.Done():
			return
		}
	}
}

func (a *App) ReloadPeers(ctx context.Context) {
	newPeers, err := a.Detector.Discover()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Discovery failed during reload: %v\n", err)
		return
	}

	a.mu.Lock()
	defer a.mu.Unlock()

	// 1. Identify and stop pings for peers that no longer exist
	newMap := make(map[string]bool)
	for _, p := range newPeers {
		newMap[p.TargetIP] = true
	}

	for ip, cancel := range a.active {
		if !newMap[ip] {
			fmt.Printf("Stopping monitor for removed peer: %s\n", ip)
			cancel()
			delete(a.active, ip)
		}
	}

	// 2. Start pings for new peers
	for _, p := range newPeers {
		if _, running := a.active[p.TargetIP]; !running {
			fmt.Printf("Starting monitor for new peer: %s on %s\n", p.TargetIP, p.Interface)
			pCtx, pCancel := context.WithCancel(ctx)
			a.active[p.TargetIP] = pCancel
			go a.Monitor.RunPingLoop(pCtx, p.TargetIP)
		}
	}

	a.Peers = newPeers
	fmt.Printf("Discovery complete. Monitoring %d peers.\n", len(a.Peers))
}

func (a *App) printSummary() {
	a.mu.RLock()
	defer a.mu.RUnlock()

	fmt.Printf("\n--- Status %s ---\n", time.Now().Format("15:04:05"))
	for _, p := range a.Peers {
		s := a.Monitor.GetStats(p.TargetIP)
		fmt.Printf("Peer: %-25s | Median: %-10v | Samples: %d/%d\n",
			p.TargetIP, s.Median.Round(time.Microsecond), s.Count, maxSamples)
	}
}

func main() {
	detector := &PeerDetector{}
	peers, err := detector.Discover()
	if err != nil {
		fmt.Printf("Discovery error: %v\n", err)
		return
	}

	monitor, err := NewLatencyMonitor()
	if err != nil {
		fmt.Printf("Monitor error: %v\n", err)
		return
	}

	var configDir string
	if value, ok := os.LookupEnv("RUNTIME_DIRECTORY"); ok {
		configDir = value
	} else {
		if len(os.Args) < 2 {
			fmt.Println("Usage: pinger <config_path>")
			fmt.Println("	or RUNTIME_DIRECTORY=<config_path> pinger")
			return
		}
		configDir = os.Args[1]
	}

	// RuntimeDirectory
	app := &App{
		Monitor:  monitor,
		Detector: detector,
		Exporter: &BGPExporter{ConfigDir: configDir},
		Peers:    peers,
	}

	app.Start(context.Background())
}
