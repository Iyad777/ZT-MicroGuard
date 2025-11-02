package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
)

// Define the response structure
type UserData struct {
    ID       string  `json:"id"`
    Username string  `json:"username"`
    Balance  float64 `json:"balance"`
    CallerID string  `json:"caller_spiffe_id"`
    Service  string  `json:"service"`
}

// Handler for the protected endpoint
func userDataHandler(w http.ResponseWriter, r *http.Request) {
    // Envoy/OPA acts as the access control point. 
    // The service trusts the identity provided in the X-Spiffe-Id header.
    callerID := r.Header.Get("X-Spiffe-Id")
    
    if callerID == "" {
        // This should theoretically not happen if Envoy is configured correctly.
        http.Error(w, `{"error": "Authentication failed: No SPIFFE ID provided by proxy"}`, http.StatusUnauthorized)
        return
    }

    log.Printf("ACCESS GRANTED: Request for user-data from caller ID: %s", callerID)

    // Mock sensitive data response
    data := UserData{
        ID:       "user-123",
        Username: "demo_user",
        Balance:  1500.75,
        CallerID: callerID,
        Service:  "user-service",
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(data)
}

// Simple health check
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "user-service"}`)
}

func main() {
    http.HandleFunc("/user-data", userDataHandler)
    http.HandleFunc("/health", healthHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("User Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}