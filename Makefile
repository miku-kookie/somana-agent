# Makefile for Somana Go project

# Variables
BINARY_NAME=somana
BUILD_DIR=bin
MAIN_PATH=./cmd/server
GO_VERSION=1.21.6
GO_ARCH=linux-arm64

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod

.PHONY: all build clean test deps generate run help publish-openapi download-api install-go install-tools setup

# Default target
all: clean build

# Install Go if not present
install-go:
	@echo "Checking Go installation..."
	@if ! command -v go > /dev/null; then \
		echo "Installing Go $(GO_VERSION)..."; \
		cd /tmp; \
		wget https://go.dev/dl/go$(GO_VERSION).$(GO_ARCH).tar.gz; \
		sudo tar -C /usr/local -xzf go$(GO_VERSION).$(GO_ARCH).tar.gz; \
		rm go$(GO_VERSION).$(GO_ARCH).tar.gz; \
		cd -; \
		if ! grep -q "/usr/local/go/bin" ~/.bashrc; then \
			echo 'export PATH=$$PATH:/usr/local/go/bin' >> ~/.bashrc; \
		fi; \
		export PATH=$$PATH:/usr/local/go/bin; \
		echo "Go installed successfully"; \
	else \
		echo "Go is already installed"; \
	fi

# Install required tools
install-tools: install-go
	@echo "Installing required tools..."
	@export PATH=$$PATH:/usr/local/go/bin; \
	go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest; \
	go install github.com/swaggo/swag/cmd/swag@latest; \
	echo "Tools installed successfully"

# Complete setup including Go installation
setup: install-tools download-api deps generate
	@echo "Setup completed successfully!"

# Build the application (includes code generation)
build: generate
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@export PATH=$$PATH:/usr/local/go/bin; \
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# Clean build artifacts and generated files
clean:
	@echo "Cleaning..."
	@export PATH=$$PATH:/usr/local/go/bin; \
	$(GOCLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -rf internal/generated

# Run tests
test:
	@echo "Running tests..."
	@export PATH=$$PATH:/usr/local/go/bin; \
	$(GOTEST) -v ./...

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@export PATH=$$PATH:/usr/local/go/bin; \
	$(GOMOD) tidy; \
	$(GOMOD) download; \
	go get github.com/oapi-codegen/runtime

# Download OpenAPI specification from GitHub
download-api:
	@echo "Downloading OpenAPI specification from GitHub..."
	@mkdir -p api
	@curl -L -o api/openapi.yaml https://github.com/miku-kookie/somana/releases/download/v1.0.2/openapi.yaml
	@echo "OpenAPI specification downloaded to api/openapi.yaml"

# Generate code from OpenAPI spec
generate:
	@echo "Generating code from OpenAPI spec..."
	@mkdir -p internal/generated
	@export PATH=$$PATH:/usr/local/go/bin; \
	if command -v ~/go/bin/oapi-codegen > /dev/null; then \
		~/go/bin/oapi-codegen -package generated -generate types api/openapi.yaml > internal/generated/types.go; \
		~/go/bin/oapi-codegen -package generated -generate gin-server api/openapi.yaml > internal/generated/server.go; \
		echo "Code generation complete"; \
	else \
		echo "oapi-codegen not found. Installing..."; \
		go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest; \
		~/go/bin/oapi-codegen -package generated -generate types api/openapi.yaml > internal/generated/types.go; \
		~/go/bin/oapi-codegen -package generated -generate gin-server api/openapi.yaml > internal/generated/server.go; \
		echo "Code generation complete"; \
	fi

# Generate Swagger documentation
generate-docs:
	@echo "Generating Swagger documentation..."
	@export PATH=$$PATH:/usr/local/go/bin; \
	if command -v swag > /dev/null; then \
		swag init -g $(MAIN_PATH)/main.go -o ./docs; \
	else \
		echo "swag not found. Installing..."; \
		go install github.com/swaggo/swag/cmd/swag@latest; \
		swag init -g $(MAIN_PATH)/main.go -o ./docs; \
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
	@echo "  setup         - Complete setup (install Go, tools, deps, generate code)"
	@echo "  install-go    - Install Go if not present"
	@echo "  install-tools - Install Go and required tools"
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