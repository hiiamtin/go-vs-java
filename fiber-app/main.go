package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var db *gorm.DB

// CorrelationIDMiddleware adds correlation ID to all requests
func CorrelationIDMiddleware(c *fiber.Ctx) error {
	// Handle correlation ID
	correlationId := c.Get("X-Correlation-ID")
	if correlationId == "" {
		correlationId = uuid.New().String()
	}

	// (Important!) "Force" Go to copy the string.
	safeCorrID := string(correlationId)
	// or use Fiber method (same result)
	// safeCorrID := utils.CopyString(corrID)

	//Store in request attribute for potential use in controllers
	// This allows other handlers (such as /users) to retrieve it.
	c.Locals("correlationID", safeCorrID)

	// (Safe) Send the "safe one" into Goroutine.
	// go func() {
	// // (Safe) safeCorrID will always be a valid value.
	// 	log.Println("Request received", safeCorrID)
	// }()
	c.Set("X-Correlation-ID", safeCorrID)
	return c.Next()
}

// User struct for database operations
type User struct {
	ID              int        `json:"id" gorm:"primaryKey;autoIncrement"`
	Name            string     `json:"name" gorm:"not null"`
	Email           string     `json:"email" gorm:"not null;unique"`
	LastContactDate *time.Time `json:"last_contact_date"`
}

// InteractionLog struct for database operations
type InteractionLog struct {
	ID         int       `json:"id" gorm:"primaryKey;autoIncrement"`
	CustomerID int       `json:"customer_id" gorm:"not null;index"`
	Note       string    `json:"note" gorm:"type:text"`
	Type       string    `json:"type" gorm:"not null"`
	CreatedAt  time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// TableName specifies the table name for GORM
func (InteractionLog) TableName() string {
	return "interaction_log"
}

// TableName specifies the table name for GORM
func (User) TableName() string {
	return "users"
}

// CPU work request
type CPURequest struct {
	Name string `json:"name"`
}

// CPU work response
type CPUResponse struct {
	ProcessedName string `json:"processed_name"`
}

// Interaction request for realistic transaction test
type InteractionRequest struct {
	CustomerID int    `json:"customerId"`
	Note       string `json:"note"`
	Type       string `json:"type"`
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
	dsn := "host=db user=poc_user password=poc_password dbname=poc_db port=5432 sslmode=disable TimeZone=UTC"
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		PrepareStmt: true,
	})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Test the connection
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("Failed to get database instance:", err)
	}

	sqlDB.SetMaxOpenConns(50)
	sqlDB.SetMaxIdleConns(50)
	sqlDB.SetConnMaxLifetime(5 * time.Minute)
	sqlDB.SetConnMaxIdleTime(2 * time.Minute)

	if err = sqlDB.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Database connected successfully")
}

func main() {
	// Initialize database connection
	initDatabase()

	// Initialize Fiber app
	app := fiber.New()

	// Add correlation ID middleware to all routes
	app.Use(CorrelationIDMiddleware)

	// API 1: GET /plaintext - Returns "Hello, World!"
	app.Get("/plaintext", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World!")
	})

	// API 2: POST /json - Receives LargeJSON, returns status
	app.Post("/json", func(c *fiber.Ctx) error {
		var jsonBody map[string]interface{}
		if err := c.BodyParser(&jsonBody); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid JSON"})
		}

		return c.Status(fiber.StatusOK).JSON(StatusResponse{Status: "ok"})
	})

	// API 3: POST /cpu - CPU intensive work
	app.Post("/cpu", func(c *fiber.Ctx) error {
		var req CPURequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request"})
		}

		result := perform_cpu_work(req.Name)
		return c.Status(fiber.StatusOK).JSON(CPUResponse{ProcessedName: result})
	})

	// API 4: GET /db - Database read test
	app.Get("/db", func(c *fiber.Ctx) error {
		var user User
		err := db.First(&user, 10).Error

		if err != nil {
			if err == gorm.ErrRecordNotFound {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
			}
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Database error"})
		}

		return c.Status(fiber.StatusOK).JSON(user)
	})

	// API 5: POST /interaction - Realistic transaction (main test)
	app.Post("/interaction", func(c *fiber.Ctx) error {
		var req InteractionRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request"})
		}

		// Validate interaction type
		validTypes := map[string]bool{
			"CALL": true, "EMAIL": true, "MEETING": true,
			"PURCHASE": true, "SUPPORT": true, "OTHER": true,
		}
		if !validTypes[req.Type] {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER",
				"code":  "INVALID_INTERACTION_TYPE",
			})
		}

		// Start database transaction
		tx := db.Begin()
		if tx.Error != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Transaction failed"})
		}

		// Read user to verify exists (with pessimistic lock)
		var user User
		err := tx.Set("gorm:query_option", "FOR UPDATE").First(&user, req.CustomerID).Error
		if err != nil {
			tx.Rollback()
			if err == gorm.ErrRecordNotFound {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
					"error": fmt.Sprintf("Customer with ID %d not found", req.CustomerID),
					"code":  "CUSTOMER_NOT_FOUND",
				})
			}
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Database error"})
		}

		// Insert interaction log
		interaction := InteractionLog{
			CustomerID: req.CustomerID,
			Note:       req.Note,
			Type:       req.Type,
		}
		err = tx.Create(&interaction).Error
		if err != nil {
			tx.Rollback()
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create interaction"})
		}

		// Update user's last contact date
		now := time.Now()
		err = tx.Model(&user).Update("last_contact_date", &now).Error
		if err != nil {
			tx.Rollback()
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update user"})
		}

		// Commit transaction
		err = tx.Commit().Error
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Transaction commit failed"})
		}

		// Return the created interaction
		err = db.First(&interaction, interaction.ID).Error
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve created interaction"})
		}

		return c.Status(fiber.StatusCreated).JSON(interaction)
	})

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{"status": "healthy"})
	})

	// Start server
	log.Println("Fiber server starting on :8080")
	if err := app.Listen(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
