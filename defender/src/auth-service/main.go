package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func rootHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"message": "Auth Service is running. It is another internal service."}`)
}

func main() {
    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprint(w, `{"status": "ok", "service": "auth-service"}`)
    })

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Auth Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}