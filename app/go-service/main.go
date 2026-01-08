package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
	Hostname  string    `json:"hostname"`
}

const version = "1.0.0"

func main() {
	port := getEnv("PORT", "8080")
	
	http.HandleFunc("/", handleRoot)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/healthz", handleHealth)
	
	log.Printf("🚀 Starting Chaos Edge App v%s on port %s", version, port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><title>Chaos Edge DevOps</title>
<style>
body{font-family:Arial;background:linear-gradient(135deg,#667eea,#764ba2);color:white;
display:flex;justify-content:center;align-items:center;height:100vh;margin:0}
.container{text-align:center;padding:3rem;border-radius:20px;
background:rgba(255,255,255,0.1);backdrop-filter:blur(10px)}
h1{font-size:3rem;margin:0}.emoji{font-size:4rem}
</style></head>
<body><div class="container">
<div class="emoji">🚀</div><h1>Chaos Edge DevOps</h1>
<p>Version: %s | Host: %s</p>
<p><a href="/health" style="color:white">Health Check</a></p>
</div></body></html>`, version, hostname)
	
	w.Header().Set("Content-Type", "text/html")
	fmt.Fprint(w, html)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Version:   version,
		Hostname:  hostname,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
