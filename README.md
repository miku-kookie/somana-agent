# Somana Agent

A simple Go server for Linux host management, inspired by the [Somana project](https://github.com/miku-kookie/somana).

## Overview

Somana Agent is a lightweight host management API that allows you to register, monitor, and manage Linux hosts. It provides a RESTful API for host registration, status updates, and health monitoring.

## Features

- Host registration and management
- Health monitoring
- SQLite database storage
- RESTful API endpoints
- Simple and clean architecture

## Quick Start

1. **Install dependencies:**
   ```bash
   go mod tidy
   ```

2. **Run the server:**
   ```bash
   go run cmd/server/main.go
   ```

3. **Test the API:**
   ```bash
   # Health check
   curl http://localhost:8080/health
   
   # Register a host
   curl -X POST http://localhost:8080/api/v1/hosts \
     -H "Content-Type: application/json" \
     -d '{
       "hostname": "web-server-01",
       "ip_address": "192.168.1.100",
       "os_name": "Ubuntu",
       "os_version": "22.04.3 LTS"
     }'
   
   # List all hosts
   curl http://localhost:8080/api/v1/hosts
   ```

## API Endpoints

### Host Management
- `GET /api/v1/hosts` - List all hosts
- `POST /api/v1/hosts` - Register a new host
- `GET /api/v1/hosts/:id` - Get a specific host by ID
- `PUT /api/v1/hosts/:id` - Update a host
- `DELETE /api/v1/hosts/:id` - Deregister a host
- `POST /api/v1/hosts/:id/heartbeat` - Update host status/heartbeat

### Health Check
- `GET /health` - Health check endpoint

## Project Structure

```
somana-agent/
├── cmd/
│   └── server/
│       └── main.go          # Application entry point
├── internal/
│   ├── database/
│   │   └── database.go      # Database connection and setup
│   ├── models/
│   │   └── host.go          # Host model definition
│   └── handlers/
│       └── host_handlers.go # HTTP request handlers
├── go.mod                   # Go module definition
└── README.md               # This file
```

## Host Model

The Host model includes:
- `ID` - Unique identifier (auto-generated)
- `Hostname` - Hostname of the system
- `IPAddress` - IP address of the system
- `OSName` - Operating system name
- `OSVersion` - Operating system version
- `Status` - Current status (online, offline, maintenance)
- `CreatedAt` - Registration timestamp
- `UpdatedAt` - Last update timestamp
- `DeletedAt` - Soft delete timestamp (nullable)

## Database

The application uses SQLite with GORM for database operations. The database file will be automatically created in the `data/` directory when the application starts.

Default database location: `data/somana.db`

## License

MIT License 