package database

import (
	"log"
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"somana-agent/internal/generated"
)

var DB *gorm.DB

// InitDatabase initializes the database connection and runs migrations
func InitDatabase() error {
	// Create data directory if it doesn't exist
	dataDir := "data"
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return err
	}

	// Database file path
	dbPath := filepath.Join(dataDir, "somana.db")

	// Open database connection
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return err
	}

	// Auto migrate the schema using the generated Host type
	if err := db.AutoMigrate(&generated.Host{}); err != nil {
		return err
	}

	DB = db
	log.Printf("Database initialized successfully at %s", dbPath)
	return nil
}

// GetDB returns the database instance
func GetDB() *gorm.DB {
	return DB
} 