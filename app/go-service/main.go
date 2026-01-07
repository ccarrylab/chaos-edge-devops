package main
import ("fmt"; "log"; "net/http"; "time")
func main() {
    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200); fmt.Fprintln(w, "OK - Chaos Edge LIVE")
    })
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200); fmt.Fprintf(w, "Chaos Edge Demo\nTime: %s\n", time.Now())
    })
    log.Fatal(http.ListenAndServe(":8080", nil))
}
