#!/bin/bash
set -e

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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if ! docker compose version > /dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to create docker-compose.yml if it doesn't exist
create_docker_compose() {
    if [ ! -f docker-compose.yml ]; then
        print_status "Creating docker-compose.yml from compose.example.yml..."
        cp compose.example.yml docker-compose.yml
        print_success "docker-compose.yml created successfully"
    else
        print_status "docker-compose.yml already exists"
    fi
}

# Function to create .env file if it doesn't exist
create_env_file() {
    if [ ! -f .env ]; then
        print_status "Creating .env file with default values..."
        cat > .env << EOL
# Database configuration
POSTGRES_USER=maybe_user
POSTGRES_PASSWORD=maybe_password
POSTGRES_DB=maybe_production

# Rails configuration
SECRET_KEY_BASE=a7523c3d0ae56415046ad8abae168d71074a79534a7062258f8d1d51ac2f76d3c3bc86d86b6b0b307df30d9a6a90a2066a3fa9e67c5e6f374dbd7dd4e0778e13
SELF_HOSTED=true
RAILS_FORCE_SSL=false
RAILS_ASSUME_SSL=false

# OpenAI configuration (optional - for AI features)
# OPENAI_ACCESS_TOKEN=your_openai_token_here
EOL
        print_success ".env file created successfully"
        print_warning "Please review and update the .env file with your specific configuration"
    else
        print_status ".env file already exists"
    fi
}

# Function to create necessary directories
create_directories() {
    mkdir -p storage logs tmp
    print_success "Created necessary directories"
}

# Function to check if services are healthy
check_services_health() {
    print_status "Checking if services are healthy..."
    
    # Wait for database to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec -T db pg_isready -U maybe_user -d maybe_production > /dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Database failed to become ready after $max_attempts attempts"
            exit 1
        fi
        
        print_status "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Wait for Redis to be ready
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
            print_success "Redis is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Redis failed to become ready after $max_attempts attempts"
            exit 1
        fi
        
        print_status "Waiting for Redis... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Function to run database setup
setup_database() {
    print_status "Setting up database..."
    docker compose exec -T web rails db:prepare
    print_success "Database setup completed"
}

# Function to display final status
display_status() {
    echo ""
    print_success "Maybe is now running!"
    echo ""
    echo -e "${GREEN}Access the application:${NC}"
    echo "  Web interface: http://localhost:3000"
    echo ""
    echo -e "${GREEN}Useful commands:${NC}"
    echo "  View logs:        docker compose logs -f"
    echo "  Stop services:    docker compose down"
    echo "  Restart services: docker compose restart"
    echo "  Shell access:     docker compose exec web bash"
    echo ""
    echo -e "${GREEN}Services running:${NC}"
    docker compose ps
}

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Maybe Finance App Starter${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_docker
    check_docker_compose
    
    # Create necessary files and directories
    print_status "Setting up configuration files..."
    create_docker_compose
    create_env_file
    create_directories
    
    # Build and start the containers
    print_status "Building and starting containers..."
    docker compose build --no-cache
    docker compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 10
    
    # Check if services are running
    if ! docker compose ps | grep -q "Up"; then
        print_error "Some services failed to start. Check the logs with 'docker compose logs'"
        exit 1
    fi
    
    # Check service health
    check_services_health
    
    # Setup database
    setup_database
    
    # Display final status
    display_status
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping Maybe services..."
        docker compose down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting Maybe services..."
        docker compose restart
        print_success "Services restarted"
        ;;
    "logs")
        docker compose logs -f
        ;;
    "shell")
        docker compose exec web bash
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Start the Maybe application"
        echo "  stop       Stop all services"
        echo "  restart    Restart all services"
        echo "  logs       Show service logs"
        echo "  shell      Open shell in web container"
        echo "  help       Show this help message"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 