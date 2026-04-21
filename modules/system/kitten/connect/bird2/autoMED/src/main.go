package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/exec"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"github.com/vishvananda/netlink"
	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv6"
)

const maxSamples = 100 // Only keep the last 100 results per IP

var (
	configPath = os.Args[1]
)

type Pinger struct {
	conn    *icmp.PacketConn
	id      int
	pending map[uint32]chan time.Time
	mu      sync.Mutex
	stats   map[string][]time.Duration
	targetIF map[string]string
	seq     uint32
}

func NewPinger() (*Pinger, error) {
	c, err := icmp.ListenPacket("ip6:ipv6-icmp", "::")
	if err != nil {
		return nil, err
	}
	p := &Pinger{
		conn:    c,
		id:      os.Getpid() & 0xffff,
		pending: make(map[uint32]chan time.Time),
		stats:   make(map[string][]time.Duration),
		targetIF: make(map[string]string),
	}
	go p.listen()
	return p, nil
}

// WriteBGPConfig exports the stats to a file formatted for BGP MEDs
func (p *Pinger) WriteBGPConfig() {
	p.mu.Lock()
	targets := make([]string, 0, len(p.stats))
	for t := range p.targetIF {
		targets = append(targets, t)
	}
	p.mu.Unlock()

	f, err := os.Create(configPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating config file: %v\n", err)
		return
	}

	for _, t := range targets {
		var medValue int64

		_, median := p.GetStats(t)
		if median != 0 {
			// Use the Median in milliseconds as the MED value
			medValue = int64(median.Round(time.Microsecond)) / 1000
		} else {
			medValue = 1000 * 1000
		}

		ifName := p.targetIF[t]

		// Format: define bgpMED_eth0 = 12;
		line := fmt.Sprintf("define bgpMED_%s = %d;\n", ifName, medValue)
		f.WriteString(line)
	}
	f.Close()

	cmd := exec.Command("birdc", "configure")
	err = cmd.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s > Failed to trigger birdc: %v\n", time.Now().Format("15:04:05"), err)
	} else {
		fmt.Fprintf(os.Stderr, "%s > BGP Config written and BIRD reconfigured.\n", time.Now().Format("15:04:05"))
	}
}

func (p *Pinger) listen() {
	for {
		reply := make([]byte, 1500)
		n, _, err := p.conn.ReadFrom(reply)
		if err != nil {
			return
		}

		rm, err := icmp.ParseMessage(58, reply[:n])
		if err != nil || rm.Type != ipv6.ICMPTypeEchoReply {
			continue
		}

		echo, ok := rm.Body.(*icmp.Echo)
		if !ok || echo.ID != p.id {
			continue
		}

		p.mu.Lock()
		if ch, exists := p.pending[uint32(echo.Seq)]; exists {
			ch <- time.Now()
			delete(p.pending, uint32(echo.Seq))
		}
		p.mu.Unlock()
	}
}

func (p *Pinger) Ping(ctx context.Context, ip net.IP) (time.Duration, error) {
	s := atomic.AddUint32(&p.seq, 1) & 0xffff
	waiter := make(chan time.Time, 1)

	p.mu.Lock()
	p.pending[s] = waiter
	p.mu.Unlock()

	msg := icmp.Message{
		Type: ipv6.ICMPTypeEchoRequest,
		Code: 0,
		Body: &icmp.Echo{ID: p.id, Seq: int(s), Data: []byte("GOPHER")},
	}

	bin, _ := msg.Marshal(nil)
	start := time.Now()
	if _, err := p.conn.WriteTo(bin, &net.IPAddr{IP: ip}); err != nil {
		return 0, err
	}

	select {
	case end := <-waiter:
		dur := end.Sub(start)
		p.record(ip.String(), dur)
		return dur, nil
	case <-ctx.Done():
		p.mu.Lock()
		delete(p.pending, s)
		p.mu.Unlock()
		return 0, ctx.Err()
	}
}

// record handles the rolling window logic
func (p *Pinger) record(ip string, dur time.Duration) {
	p.mu.Lock()
	defer p.mu.Unlock()

	p.stats[ip] = append(p.stats[ip], dur)

	// If we exceed maxSamples, remove the oldest (first) element
	if len(p.stats[ip]) > maxSamples {
		p.stats[ip] = p.stats[ip][1:]
	}
}

func (p *Pinger) GetStats(target string) (mean time.Duration, median time.Duration) {
	p.mu.Lock()
	durations, ok := p.stats[target]
	if !ok || len(durations) == 0 {
		p.mu.Unlock()
		return 0, 0
	}
	// Copy slice to avoid holding lock during calculation or sorting original
	temp := make([]time.Duration, len(durations))
	copy(temp, durations)
	p.mu.Unlock()

	var total time.Duration
	for _, d := range temp {
		total += d
	}
	mean = total / time.Duration(len(temp))

	sort.Slice(temp, func(i, j int) bool { return temp[i] < temp[j] })
	l := len(temp)
	if l%2 == 0 {
		median = (temp[l/2-1] + temp[l/2]) / 2
	} else {
		median = temp[l/2]
	}

	return mean, median
}

// Loop now runs silently, only recording data
func (p *Pinger) Loop(ctx context.Context, target string, initialInterval time.Duration) {
	ip := net.ParseIP(target)
	// Define the "slow" interval (e.g., 5x slower)
	slowInterval := initialInterval * 5

	// Use a Timer instead of a Ticker for dynamic adjustments
	timer := time.NewTimer(initialInterval)
	defer timer.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
			pCtx, cancel := context.WithTimeout(ctx, initialInterval)
			_, err := p.Ping(pCtx, ip)

			// p.mu.Lock()
			count := len(p.stats[ip.String()])
			// p.mu.Unlock()

			nextInterval := initialInterval
			// status := "Warm-up"

			if count >= maxSamples {
				nextInterval = slowInterval
				// status = "Steady State (Slow)"
			}
			// 3. Output results
			if err != nil {
				fmt.Fprintf(os.Stderr, "[%s] Error: %v\n", target, err)
			}
			cancel()
			timer.Reset(nextInterval)
		}
	}
}

// PrintRecap iterates through all tracked IPs and prints their current stats
func (p *Pinger) PrintRecap() {
	p.mu.Lock()
	// Get a list of targets to avoid holding the lock while calculating
	targets := make([]string, 0, len(p.stats))
	for t := range p.stats {
		targets = append(targets, t)
	}
	p.mu.Unlock()

	fmt.Fprintf(os.Stderr, "\n--- Periodic Recap (%s) ---\n", time.Now().Format("15:04:05"))
	if len(targets) == 0 {
		fmt.Fprintf(os.Stderr, "No data collected yet.")
		return
	}

	for _, t := range targets {
		mean, median := p.GetStats(t)
		fmt.Fprintf(os.Stderr, "Target: %-25s | Avg: %-12v | Median: %-12v | Samples: %d/%d\n",
			t, mean.Round(time.Microsecond), median.Round(time.Microsecond), len(p.stats[t]), maxSamples)
	}
	fmt.Fprintf(os.Stderr, "------------------------------------------")
}

func (p *Pinger) Close() { p.conn.Close() }

type MonitoredPeer struct {
	netlink.Addr
	iface netlink.Link
}

// DetectIPv6Addresses queries the kernel via netlink for global IPv6 addresses
func DetectIPv6Addresses() ([]MonitoredPeer, error) {
	var addrs []MonitoredPeer

	// Get all network interfaces
	links, err := netlink.LinkList()
	if err != nil {
		return nil, err
	}

	for _, link := range links {
		// Get addresses for this specific link
		list, err := netlink.AddrList(link, netlink.FAMILY_V6)
		if err != nil {
			continue
		}

		for _, addr := range list {
			ip := addr.IP
			// We only want Global Unicast addresses
			// Filter out Link-Local (fe80::), Loopback (::1), and Multicast
			if ip.IsGlobalUnicast() && !ip.IsLoopback() {
				addrs = append(addrs, MonitoredPeer{addr, link})
			}
		}
	}

	if len(addrs) == 0 {
		return nil, fmt.Errorf("no global IPv6 addresses found")
	}
	return addrs, nil
}

func GetIPv6Peer(ip net.IP) net.IP {
	// Make a copy of the IP so we don't modify the original
	peerIP := make(net.IP, len(ip))
	copy(peerIP, ip)

	// Get the last byte
	lastIndex := len(peerIP) - 1
	lastByte := peerIP[lastIndex]

	// Your logic:
	// If even (isFirst), add 1. If odd, subtract 1.
	if lastByte%2 == 0 {
		peerIP[lastIndex] = lastByte + 1
	} else {
		peerIP[lastIndex] = lastByte - 1
	}

	return peerIP
}

func main() {
	// 1. Detection and Peer Calculation
	myAddrs, err := DetectIPv6Addresses()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Detection failed: %v\n", err)
		return
	}

	p, err := NewPinger()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Permission Error: %v\n", err)
		return
	}
	defer p.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 2. Start silent loops for all detected peers
	var wg sync.WaitGroup
	for _, addr := range myAddrs {
		ones, bits := addr.Mask.Size()

		// Check if the mask is exactly /127
		if ones != 127 || bits != 128 {
			continue
		}


		peerIP := GetIPv6Peer(addr.IP)
		p.targetIF[peerIP.String()] = addr.iface.Attrs().Name
		fmt.Fprintf(os.Stderr, "Monitoring Peer: %s (via %s on %s)\n", peerIP.String(), addr.IP.String(), addr.iface.Attrs().Name)

		wg.Add(1)
		go func(target net.IP) {
			defer wg.Done()
			p.Loop(ctx, target.String(), time.Second)
		}(peerIP)
	}

	go func() {
		fileTicker := time.NewTicker(1 * time.Minute)
		defer fileTicker.Stop()
		p.WriteBGPConfig()
		for {
			select {
				case <-fileTicker.C:
					p.WriteBGPConfig()
					fmt.Fprintf(os.Stderr, "BGP MED config file %s updated at %s\n", configPath, time.Now().Format("15:04:05"))
				case <-ctx.Done():
					return
			}
		}
	}()

	// 3. The Recap Ticker
	// This goroutine handles the 10-second summary
	go func() {
		recapTicker := time.NewTicker(10 * time.Second)
		defer recapTicker.Stop()
		for {
			select {
			case <-recapTicker.C:
				p.PrintRecap()
			case <-ctx.Done():
				return
			}
		}
	}()

	fmt.Fprintf(os.Stderr, "Pinger active. Summary will print every 10s. Press Ctrl+C to stop.\n")
	wg.Wait()
}
