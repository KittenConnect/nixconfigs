package main

import (
	"fmt"
	"os"
	"os/exec"
	"time"
)

// --- Domain 3: BGP Config Management ---

type BGPExporter struct {
	ConfigDir string // Now expects a directory path (e.g., "/etc/bird/med.d/")
}

func (e *BGPExporter) Export(peers []MonitoredPeer, lm *LatencyMonitor) {
	// 1. Ensure the directory exists
	if err := os.MkdirAll(e.ConfigDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create config directory: %v\n", err)
		return
	}

	for _, peer := range peers {
		stats := lm.GetStats(peer.TargetIP)

		// Use a high penalty (2^31 - 1) if no data is available yet
		medValue := int64(2147483647)
		if stats.Median != 0 {
			medValue = stats.Median.Milliseconds()
		}

		// 2. Create a file named after the interface (e.g., eth0.conf)
		filePath := fmt.Sprintf("%s/%s.conf", e.ConfigDir, peer.Interface)
		content := []byte(fmt.Sprintf("define bgpMED_%s = %d;\n", peer.Interface, medValue))

		err := os.WriteFile(filePath, content, 0644)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error writing file %s: %v\n", filePath, err)
			continue
		}
	}

	// 3. Notify BIRD to reload configuration
	err := exec.Command("birdc", "configure").Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s > Failed to trigger birdc: %v\n",
			    time.Now().Format("15:04:05"), err)
	} else {
		fmt.Fprintf(os.Stderr, "%s > BGP Peer configs updated and BIRD reconfigured.\n",
			    time.Now().Format("15:04:05"))
	}
}
