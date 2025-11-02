package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
)

type UserData struct {
    ID       string  `json:"id"`
    Username string  `json:"username"`
    Balance  float64 `json:"balance"`
    CallerID string  `json:"caller_spiffe_id"`
    Service  string  `json:"service"`
}

// Existing handler
func userDataHandler(w http.ResponseWriter, r *http.Request) {
    callerID := r.Header.Get("X-Spiffe-Id")
    
    if callerID == "" {
        http.Error(w, `{"error": "Authentication failed: No SPIFFE ID provided by proxy"}`, http.StatusUnauthorized)
        return
    }

    log.Printf("ACCESS GRANTED: Request for user-data from caller ID: %s", callerID)

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

// NEW: Handler for /users/data (same as /user-data but with prefix)
func usersDataHandler(w http.ResponseWriter, r *http.Request) {
    userDataHandler(w, r) // Reuse the same logic
}

// NEW: Handler for /users/health
func usersHealthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "user-service", "endpoint": "users-health"}`)
}

// Existing health handler
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, `{"status": "ok", "service": "user-service"}`)
}

func main() {
    // Existing endpoints
    http.HandleFunc("/user-data", userDataHandler)
    http.HandleFunc("/health", healthHandler)
    
    // NEW endpoints for prefixed routes
    http.HandleFunc("/users/data", usersDataHandler)
    http.HandleFunc("/users/health", usersHealthHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("User Service starting on :%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatalf("could not start server: %v", err)
    }
}