package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func rootHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"message": "Payment Service is running. It is the legitimate caller."}`)
}

// NEW: Prefixed health endpoint
func paymentsHealthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "payment-service", "endpoint": "payments-health"}`)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "payment-service"}`)
}

func main() {
    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", healthHandler)
    
    // NEW endpoint
    http.HandleFunc("/payments/health", paymentsHealthHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Payment Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}