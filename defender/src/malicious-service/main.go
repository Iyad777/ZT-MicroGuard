package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func rootHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"message": "Malicious Service is running. It will be DENIED access."}`)
}

func main() {
    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprint(w, `{"status": "ok", "service": "malicious-service"}`)
    })

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Malicious Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}