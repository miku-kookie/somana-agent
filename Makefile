# Makefile for Somana Go project

# Variables
BINARY_NAME=somana
BUILD_DIR=bin
MAIN_PATH=./cmd/server

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod

.PHONY: all build clean test deps generate run help publish-openapi download-api

# Default target
all: clean build

# Build the application (includes code generation)
build: generate
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# Clean build artifacts and generated files
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -rf internal/generated

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

# Install dependencies
deps:
	@echo "Installing dependencies..."
	$(GOMOD) tidy
	$(GOMOD) download

# Download OpenAPI specification from GitHub
download-api:
	@echo "Downloading OpenAPI specification from GitHub..."
	curl -L -o api/openapi.yaml https://github.com/miku-kookie/somana/releases/download/v1.0.2/openapi.yaml
	@echo "OpenAPI specification downloaded to api/openapi.yaml"

# Generate code from OpenAPI spec
generate:
	@echo "Generating code from OpenAPI spec..."
	@mkdir -p internal/generated
	@if command -v ~/go/bin/oapi-codegen > /dev/null; then \
		~/go/bin/oapi-codegen -package generated -generate types api/openapi.yaml > internal/generated/types.go; \
		~/go/bin/oapi-codegen -package generated -generate gin-server api/openapi.yaml > internal/generated/server.go; \
		echo "Code generation complete"; \
	else \
		echo "oapi-codegen not found. Install with: go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest"; \
	fi

# Generate Swagger documentation
generate-docs:
	@echo "Generating Swagger documentation..."
	@if command -v swag > /dev/null; then \
		swag init -g $(MAIN_PATH)/main.go -o ./docs; \
	else \
		echo "swag not found. Install with: go install github.com/swaggo/swag/cmd/swag@latest"; \
	fi

# Publish OpenAPI specification to GitHub releases
publish-openapi:
	@echo "Publishing OpenAPI specification..."
	@./scripts/publish-openapi.sh $(VERSION)

# Run the application
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BUILD_DIR)/$(BINARY_NAME)

# Show help
help:
	@echo "Available targets:"
	@echo "  build         - Generate code and build the application"
	@echo "  clean         - Clean build artifacts and generated files"
	@echo "  test          - Run tests"
	@echo "  deps          - Install dependencies"
	@echo "  download-api  - Download OpenAPI specification from GitHub"
	@echo "  generate      - Generate code from OpenAPI spec"
	@echo "  generate-docs - Generate Swagger documentation"
	@echo "  publish-openapi - Publish OpenAPI spec to GitHub releases"
	@echo "  run           - Generate, build and run the application"
	@echo "  help          - Show this help" 