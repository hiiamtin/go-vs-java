package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"time"

	"github.com/gofiber/fiber/v3"
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

	// Initialize Fiber app
	app := fiber.New()

	// API 1: GET /plaintext - Returns "Hello, World!"
	app.Get("/plaintext", func(c *fiber.Ctx) error {
		c.Type("text/plain")
		return c.SendString("Hello, World!")
	})

	// API 2: POST /json - Receives LargeJSON, returns status
	app.Post("/json", func(c *fiber.Ctx) error {
		var jsonBody map[string]interface{}
		if err := c.BodyParser(&jsonBody); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid JSON"})
		}
		return c.Status(200).JSON(fiber.Map{"status": "ok"})
	})

	// API 3: POST /cpu - CPU intensive work
	app.Post("/cpu", func(c *fiber.Ctx) error {
		var req CPURequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result := perform_cpu_work(req.Name)
		return c.Status(200).JSON(fiber.Map{"processed_name": result})
	})

	// API 4: GET /db - Database read test
	app.Get("/db", func(c *fiber.Ctx) error {
		var user User
		err := db.QueryRow("SELECT id, name, email, last_contact_date FROM users WHERE id = $1", 10).
			Scan(&user.ID, &user.Name, &user.Email, &user.LastContactDate)

		if err != nil {
			if err == sql.ErrNoRows {
				return c.Status(404).JSON(fiber.Map{"error": "User not found"})
			}
			return c.Status(500).JSON(fiber.Map{"error": "Database error"})
		}

		return c.Status(200).JSON(user)
	})

	// API 5: POST /interaction - Realistic transaction (main test)
	app.Post("/interaction", func(c *fiber.Ctx) error {
		var req InteractionRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		// Validate interaction type
		validTypes := map[string]bool{
			"CALL": true, "EMAIL": true, "MEETING": true,
			"PURCHASE": true, "SUPPORT": true, "OTHER": true,
		}
		if !validTypes[req.Type] {
			return c.Status(400).JSON(fiber.Map{
				"error": "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER",
				"code":  "INVALID_INTERACTION_TYPE",
			})
		}

		// Start database transaction
		tx, err := db.Begin()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Transaction failed"})
		}

		// Read user to verify exists
		var user User
		err = tx.QueryRow("SELECT id FROM users WHERE id = $1 FOR UPDATE", req.CustomerID).
			Scan(&user.ID)
		if err != nil {
			tx.Rollback()
			if err == sql.ErrNoRows {
				return c.Status(404).JSON(fiber.Map{
					"error": fmt.Sprintf("Customer with ID %d not found", req.CustomerID),
					"code":  "CUSTOMER_NOT_FOUND",
				})
			}
			return c.Status(500).JSON(fiber.Map{"error": "Database error"})
		}

		// Insert interaction log
		var interactionID int
		err = tx.QueryRow(
			"INSERT INTO interaction_log (customer_id, note, type, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id",
			req.CustomerID, req.Note, req.Type,
		).Scan(&interactionID)
		if err != nil {
			tx.Rollback()
			return c.Status(500).JSON(fiber.Map{"error": "Failed to create interaction"})
		}

		// Update user's last contact date
		_, err = tx.Exec("UPDATE users SET last_contact_date = NOW() WHERE id = $1", req.CustomerID)
		if err != nil {
			tx.Rollback()
			return c.Status(500).JSON(fiber.Map{"error": "Failed to update user"})
		}

		// Commit transaction
		err = tx.Commit()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Transaction commit failed"})
		}

		// Return created interaction
		var interaction InteractionLog
		err = db.QueryRow(
			"SELECT id, customer_id, note, type, created_at FROM interaction_log WHERE id = $1",
			interactionID,
		).Scan(&interaction.ID, &interaction.CustomerID, &interaction.Note, &interaction.Type, &interaction.CreatedAt)

		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to retrieve created interaction"})
		}

		return c.Status(201).JSON(interaction)
	})

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(fiber.Map{"status": "healthy"})
	})

	// Start server
	log.Println("Fiber server starting on :8080")
	if err := app.Listen(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
