package main

import (
	"context"
	"net"
	"os"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv6"
)

// --- Domain 1: Latency Monitoring ---

type LatencyStats struct {
	Mean   time.Duration
	Median time.Duration
	Count  int
}

type LatencyMonitor struct {
	conn    *icmp.PacketConn
	id      int
	seq     uint32
	mu      sync.Mutex
	pending map[uint32]chan time.Time
	history map[string][]time.Duration
}

func NewLatencyMonitor() (*LatencyMonitor, error) {
	c, err := icmp.ListenPacket("ip6:ipv6-icmp", "::")
	if err != nil {
		return nil, err
	}
	lm := &LatencyMonitor{
		conn:    c,
		id:      os.Getpid() & 0xffff,
		pending: make(map[uint32]chan time.Time),
		history: make(map[string][]time.Duration),
	}
	go lm.listen()
	return lm, nil
}

func (lm *LatencyMonitor) listen() {
	for {
		reply := make([]byte, 1500)
		n, _, err := lm.conn.ReadFrom(reply)
		if err != nil {
			return
		}
		rm, err := icmp.ParseMessage(58, reply[:n])
		if err != nil || rm.Type != ipv6.ICMPTypeEchoReply {
			continue
		}
		echo, ok := rm.Body.(*icmp.Echo)
		if !ok || echo.ID != lm.id {
			continue
		}

		lm.mu.Lock()
		if ch, exists := lm.pending[uint32(echo.Seq)]; exists {
			ch <- time.Now()
			delete(lm.pending, uint32(echo.Seq))
		}
		lm.mu.Unlock()
	}
}

func (lm *LatencyMonitor) RunPingLoop(ctx context.Context, targetIP string) {
	ip := net.ParseIP(targetIP)
	timer := time.NewTimer(defaultInterval)
	defer timer.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
			pCtx, cancel := context.WithTimeout(ctx, defaultInterval)
			dur, err := lm.ping(pCtx, ip)
			cancel()

			if err == nil {
				lm.record(targetIP, dur)
			}

			// Adjust interval based on sample count (warmup vs steady state)
			interval := defaultInterval
			if lm.getSampleCount(targetIP) >= maxSamples {
				interval = defaultInterval * 5
			}
			timer.Reset(interval)
		}
	}
}

func (lm *LatencyMonitor) ping(ctx context.Context, ip net.IP) (time.Duration, error) {
	s := atomic.AddUint32(&lm.seq, 1) & 0xffff
	waiter := make(chan time.Time, 1)

	lm.mu.Lock()
	lm.pending[s] = waiter
	lm.mu.Unlock()

	msg := icmp.Message{
		Type: ipv6.ICMPTypeEchoRequest,
		Code: 0,
		Body: &icmp.Echo{ID: lm.id, Seq: int(s), Data: []byte("GOPHER")},
	}

	bin, _ := msg.Marshal(nil)
	start := time.Now()
	if _, err := lm.conn.WriteTo(bin, &net.IPAddr{IP: ip}); err != nil {
		return 0, err
	}

	select {
	case end := <-waiter:
		return end.Sub(start), nil
	case <-ctx.Done():
		lm.mu.Lock()
		delete(lm.pending, s)
		lm.mu.Unlock()
		return 0, ctx.Err()
	}
}

func (lm *LatencyMonitor) record(ip string, dur time.Duration) {
	lm.mu.Lock()
	defer lm.mu.Unlock()
	lm.history[ip] = append(lm.history[ip], dur)
	if len(lm.history[ip]) > maxSamples {
		lm.history[ip] = lm.history[ip][1:]
	}
}

func (lm *LatencyMonitor) getSampleCount(ip string) int {
	lm.mu.Lock()
	defer lm.mu.Unlock()
	return len(lm.history[ip])
}

func (lm *LatencyMonitor) GetStats(ip string) LatencyStats {
	lm.mu.Lock()
	durations, ok := lm.history[ip]
	if !ok || len(durations) == 0 {
		lm.mu.Unlock()
		return LatencyStats{}
	}
	temp := make([]time.Duration, len(durations))
	copy(temp, durations)
	lm.mu.Unlock()

	var total time.Duration
	for _, d := range temp {
		total += d
	}

	sort.Slice(temp, func(i, j int) bool { return temp[i] < temp[j] })

	median := temp[len(temp)/2]
	if len(temp)%2 == 0 {
		median = (temp[len(temp)/2-1] + temp[len(temp)/2]) / 2
	}

	return LatencyStats{
		Mean:   total / time.Duration(len(temp)),
		Median: median,
		Count:  len(temp),
	}
}
