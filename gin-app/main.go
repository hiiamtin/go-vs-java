package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"

	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

var db *sql.DB

// User struct for database operations
type User struct {
	ID              int        `json:"id"`
	Name            string     `json:"name"`
	Email           string     `json:"email"`
	LastContactDate *time.Time `json:"last_contact_date"`
}

// InteractionLog struct for database operations
type InteractionLog struct {
	ID         int       `json:"id"`
	CustomerID int       `json:"customer_id"`
	Note       string    `json:"note"`
	Type       string    `json:"type"`
	CreatedAt  time.Time `json:"created_at"`
}

// CPU work request
type CPURequest struct {
	Name string `json:"name" binding:"required"`
}

// CPU work response
type CPUResponse struct {
	ProcessedName string `json:"processed_name"`
}

// Interaction request for realistic transaction test
type InteractionRequest struct {
	CustomerID int    `json:"customerId" binding:"required"`
	Note       string `json:"note" binding:"required"`
	Type       string `json:"type" binding:"required"`
}

// Simple status response
type StatusResponse struct {
	Status string `json:"status"`
}

// CPU work function as specified in docs
func perform_cpu_work(input string) string {
	current := input

	for i := 0; i < 1000; i++ {
		hash := sha256.Sum256([]byte(current))
		current = hex.EncodeToString(hash[:])
	}

	return current
}

func initDatabase() {
	var err error
	// Database connection for Mac OS Docker setup
	dbURL := "host=db user=poc_user password=poc_password dbname=poc_db port=5432 sslmode=disable"
	db, err = sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Database connected successfully")
}

func main() {
	// Initialize database connection
	initDatabase()
	defer db.Close()

	// Initialize Gin router
	r := gin.Default()

	// API 1: GET /plaintext - Returns "Hello, World!"
	r.GET("/plaintext", func(c *gin.Context) {
		c.String(http.StatusOK, "Hello, World!")
	})

	// API 2: POST /json - Receives LargeJSON, returns status
	r.POST("/json", func(c *gin.Context) {
		var jsonBody map[string]interface{}
		if err := c.ShouldBindJSON(&jsonBody); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON"})
			return
		}
		c.JSON(http.StatusOK, StatusResponse{Status: "ok"})
	})

	// API 3: POST /cpu - CPU intensive work
	r.POST("/cpu", func(c *gin.Context) {
		var req CPURequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		result := perform_cpu_work(req.Name)
		c.JSON(http.StatusOK, CPUResponse{ProcessedName: result})
	})

	// API 4: GET /db - Database read test
	r.GET("/db", func(c *gin.Context) {
		var user User
		err := db.QueryRow("SELECT id, name, email, last_contact_date FROM users WHERE id = $1", 10).
			Scan(&user.ID, &user.Name, &user.Email, &user.LastContactDate)

		if err != nil {
			if err == sql.ErrNoRows {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		c.JSON(http.StatusOK, user)
	})

	// API 5: POST /interaction - Realistic transaction (main test)
	r.POST("/interaction", func(c *gin.Context) {
		var req InteractionRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		// Validate interaction type
		validTypes := map[string]bool{
			"CALL": true, "EMAIL": true, "MEETING": true,
			"PURCHASE": true, "SUPPORT": true, "OTHER": true,
		}
		if !validTypes[req.Type] {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER",
				"code":  "INVALID_INTERACTION_TYPE",
			})
			return
		}

		// Start database transaction
		tx, err := db.Begin()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Transaction failed"})
			return
		}

		// Read user to verify exists
		var user User
		err = tx.QueryRow("SELECT id FROM users WHERE id = $1 FOR UPDATE", req.CustomerID).
			Scan(&user.ID)
		if err != nil {
			tx.Rollback()
			if err == sql.ErrNoRows {
				c.JSON(http.StatusNotFound, gin.H{
					"error": fmt.Sprintf("Customer with ID %d not found", req.CustomerID),
					"code":  "CUSTOMER_NOT_FOUND",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		// Insert interaction log
		var interactionID int
		err = tx.QueryRow(
			"INSERT INTO interaction_log (customer_id, note, type, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id",
			req.CustomerID, req.Note, req.Type,
		).Scan(&interactionID)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create interaction"})
			return
		}

		// Update user's last contact date
		_, err = tx.Exec("UPDATE users SET last_contact_date = NOW() WHERE id = $1", req.CustomerID)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
			return
		}

		// Commit transaction
		err = tx.Commit()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Transaction commit failed"})
			return
		}

		// Return the created interaction
		var interaction InteractionLog
		err = db.QueryRow(
			"SELECT id, customer_id, note, type, created_at FROM interaction_log WHERE id = $1",
			interactionID,
		).Scan(&interaction.ID, &interaction.CustomerID, &interaction.Note, &interaction.Type, &interaction.CreatedAt)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve created interaction"})
			return
		}

		c.JSON(http.StatusCreated, interaction)
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	// Start server
	log.Println("Gin server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
