#!/bin/bash

# Somana Agent Setup Script for Jetson
# This script installs all necessary dependencies and sets up the project

set -e  # Exit on any error

echo "🚀 Starting Somana Agent setup for Jetson..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update package list
print_status "Updating package list..."
sudo apt update

# Install basic build tools
print_status "Installing basic build tools..."
sudo apt install -y build-essential curl wget git

# Install Go
print_status "Checking if Go is installed..."
if ! command -v go &> /dev/null; then
    print_status "Installing Go..."
    
    # Download Go for ARM64 (Jetson)
    GO_VERSION="1.21.6"
    GO_ARCH="linux-arm64"
    GO_TAR="go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    cd /tmp
    wget "https://go.dev/dl/${GO_TAR}"
    
    # Remove old Go installation if it exists
    sudo rm -rf /usr/local/go
    
    # Extract Go
    sudo tar -C /usr/local -xzf "${GO_TAR}"
    
    # Clean up
    rm "${GO_TAR}"
    cd -
    
    # Add Go to PATH permanently
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    
    # Update PATH for current session
    export PATH=$PATH:/usr/local/go/bin
    
    print_success "Go installed successfully"
else
    print_success "Go is already installed"
fi

# Verify Go installation and update PATH if needed
print_status "Verifying Go installation..."
if ! command -v go &> /dev/null; then
    # Try to update PATH and verify again
    export PATH=$PATH:/usr/local/go/bin
    if ! command -v go &> /dev/null; then
        print_error "Go installation failed. Please run the following commands manually:"
        print_error "wget https://go.dev/dl/go1.21.6.linux-arm64.tar.gz"
        print_error "sudo tar -C /usr/local -xzf go1.21.6.linux-arm64.tar.gz"
        print_error "export PATH=\$PATH:/usr/local/go/bin"
        print_error "Then run this script again."
        exit 1
    fi
fi

go version

# Install oapi-codegen tool
print_status "Installing oapi-codegen..."
go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest

# Install swag for documentation (optional)
print_status "Installing swag for documentation..."
go install github.com/swaggo/swag/cmd/swag@latest

# Navigate to project directory
cd "$(dirname "$0")"

# Download OpenAPI specification
print_status "Downloading OpenAPI specification..."
if [ ! -f "api/openapi.yaml" ]; then
    mkdir -p api
    curl -L -o api/openapi.yaml https://github.com/miku-kookie/somana/releases/download/v1.0.2/openapi.yaml
    print_success "OpenAPI specification downloaded"
else
    print_success "OpenAPI specification already exists"
fi

# Install Go dependencies and fix missing runtime
print_status "Installing Go dependencies..."
go mod tidy
go mod download
go get github.com/oapi-codegen/runtime

# Generate code from OpenAPI spec
print_status "Generating code from OpenAPI specification..."
make generate

# Build the application
print_status "Building the application..."
make build

# Create systemd service file
print_status "Creating systemd service file..."
sudo tee /etc/systemd/system/somana-agent.service > /dev/null <<EOF
[Unit]
Description=Somana Agent
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/bin/somana
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

# Create logs directory
mkdir -p logs

# Set up log rotation
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/somana-agent > /dev/null <<EOF
$(pwd)/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF

# Create configuration directory
mkdir -p config

# Create a basic configuration file
print_status "Creating basic configuration..."
tee config/config.yaml > /dev/null <<EOF
# Somana Agent Configuration
server:
  port: 9000
  host: "0.0.0.0"

database:
  path: "./data/somana.db"

logging:
  level: "info"
  file: "./logs/somana.log"

# Add your sensor configurations here
sensors:
  # Example sensor configuration
  # temperature:
  #   type: "temperature"
  #   location: "room1"
  #   bridge: "i2c"
EOF

# Create data directory
mkdir -p data

# Set proper permissions
chmod +x bin/somana

# Enable and start the service
print_status "Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable somana-agent.service

print_success "Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit config/config.yaml to configure your sensors"
echo "2. Start the service: sudo systemctl start somana-agent"
echo "3. Check status: sudo systemctl status somana-agent"
echo "4. View logs: journalctl -u somana-agent -f"
echo ""
echo "🌐 The API will be available at: http://localhost:9000"
echo "📚 API documentation: http://localhost:9000/swagger/index.html"
echo ""
echo "To run manually (for testing):"
echo "  ./bin/somana"
echo ""
print_warning "Don't forget to configure your sensors in config/config.yaml!" 