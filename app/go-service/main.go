package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Chaos Edge Go - Healthy")
	})

	http.HandleFunc("/chaos/latency", func(w http.ResponseWriter, r *http.Request) {
		jitter := time.Duration(rand.Intn(1500)+500) * time.Millisecond
		time.Sleep(jitter)
		fmt.Fprintf(w, "P99 Latency: %v\n", jitter)
	})

	http.HandleFunc("/chaos/fail", func(w http.ResponseWriter, r *http.Request) {
		if rand.Intn(5) < 1 {
			http.Error(w, "💥 Chaos Injected!", 500)
			return
		}
		fmt.Fprintln(w, "Chaos Survived ✓")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
