package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
)

func main() {
	http.HandleFunc("/", logSyncHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("Defaulting to port %s", port)
	}

	http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
}

func logSyncHandler(w http.ResponseWriter, r *http.Request) {
	// Handle healthchecks
	if r.URL.EscapedPath() == "/liveness_check" {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
		return
	}
	if r.URL.EscapedPath() == "/readiness_check" {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
		return
	}

	// Make sure that this is a request from something we scheduled
	auth_info := os.Getenv("AUTH_INFO")
	if auth_info == "" {
		log.Printf("AUTH_INFO not set in environment")
		http.Error(w, "cannot authenticate client", 500)
		return
	}
	if r.Header.Get("GCS-Authorization") != auth_info {
		http.NotFound(w, r)
		return
	}

	// Check that we know where logs are
	from := os.Getenv("FROM")
	if from == "" {
		log.Printf("FROM not set in environment")
		http.Error(w, "do not know where to get the logs", 500)
		return
	}
	to := os.Getenv("TO")
	if to == "" {
		log.Printf("TO not set in environment")
		http.Error(w, "do not know where to put the logs", 500)
		return
	}

	// run gsutil rsync to get the logs where they need to go
	cmd := exec.Command("gsutil", "rsync", "-rJ", from, to)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("logs failed to sync from %s to %s: %s", from, to, string(output))
		http.Error(w, "logs failed to sync", 503)
		return
	}
	log.Printf("synced logs from %s to %s", from, to)
	fmt.Fprint(w, "OK")
}
