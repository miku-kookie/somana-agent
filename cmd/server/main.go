package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"somana-agent/internal/database"
	"somana-agent/internal/generated"
	"somana-agent/internal/services"
)

func main() {
	// Initialize database
	if err := database.InitDatabase(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Create Gin router
	r := gin.Default()

	// Create host service that implements the generated ServerInterface
	hostService := services.NewHostService()

	// Register handlers using the generated code
	generated.RegisterHandlers(r, hostService)

	// Start server
	log.Println("Starting Somana Agent server on :9000")
	if err := r.Run(":9000"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
} 