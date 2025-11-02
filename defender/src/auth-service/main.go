package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
)

func rootHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"message": "Auth Service is running. It is another internal service."}`)
}

// NEW: Admin endpoint for privilege escalation attacks
func adminHandler(w http.ResponseWriter, r *http.Request) {
    callerID := r.Header.Get("X-Spiffe-Id")
    
    w.Header().Set("Content-Type", "application/json")
    
    if callerID == "spiffe://example.org/auth-service" {
        // Allow auth-service to access admin
        json.NewEncoder(w).Encode(map[string]string{
            "message": "Admin access granted",
            "role": "administrator", 
            "caller": callerID,
            "service": "auth-service",
        })
    } else {
        // Block others
        w.WriteHeader(http.StatusForbidden)
        json.NewEncoder(w).Encode(map[string]string{
            "error": "Access denied: Admin endpoint requires auth-service identity",
            "caller": callerID,
        })
    }
}

// NEW: Prefixed health endpoint
func authHealthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "auth-service", "endpoint": "auth-health"}`)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "auth-service"}`)
}

func main() {
    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", healthHandler)
    
    // NEW endpoints
    http.HandleFunc("/auth/admin", adminHandler)
    http.HandleFunc("/auth/health", authHealthHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Auth Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}