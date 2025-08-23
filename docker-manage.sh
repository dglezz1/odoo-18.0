#!/bin/bash
# Odoo 18.0 Docker Management Script
# Provides easy commands to manage Odoo Docker deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
PROJECT_NAME="odoo"

# Functions
log() {
    echo -e "${GREEN}[ODOO DOCKER]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

# Check if .env file exists
check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        warn ".env file not found. Creating from .env.example..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            info "Please edit .env file with your configuration before starting"
        else
            error ".env.example file not found"
            exit 1
        fi
    fi
}

# Generate SSL certificates
generate_ssl() {
    log "Generating SSL certificates..."
    if [ -f "generate_ssl.sh" ]; then
        chmod +x generate_ssl.sh
        ./generate_ssl.sh
    else
        error "generate_ssl.sh script not found"
        exit 1
    fi
}

# Build Docker images
build() {
    log "Building Docker images..."
    check_docker
    check_env
    
    docker-compose -f $COMPOSE_FILE build --no-cache
    log "Docker images built successfully!"
}

# Start services
start() {
    log "Starting Odoo services..."
    check_docker
    check_env
    
    # Generate SSL certificates if they don't exist
    if [ ! -f "nginx/ssl/server.crt" ]; then
        generate_ssl
    fi
    
    docker-compose -f $COMPOSE_FILE up -d
    log "Services started successfully!"
    
    info "Waiting for services to be ready..."
    sleep 10
    
    info "Access URLs:"
    info "  HTTP:  http://localhost:80"
    info "  HTTPS: https://localhost:443"
    info "  Direct: http://localhost:8069"
    
    info "Default credentials:"
    info "  Username: admin"
    info "  Password: admin"
}

# Stop services
stop() {
    log "Stopping Odoo services..."
    docker-compose -f $COMPOSE_FILE down
    log "Services stopped successfully!"
}

# Restart services
restart() {
    log "Restarting Odoo services..."
    stop
    start
}

# Show logs
logs() {
    if [ -z "$2" ]; then
        docker-compose -f $COMPOSE_FILE logs -f
    else
        docker-compose -f $COMPOSE_FILE logs -f "$2"
    fi
}

# Show status
status() {
    docker-compose -f $COMPOSE_FILE ps
}

# Execute command in Odoo container
exec_odoo() {
    if [ -z "$2" ]; then
        docker-compose -f $COMPOSE_FILE exec odoo bash
    else
        docker-compose -f $COMPOSE_FILE exec odoo "${@:2}"
    fi
}

# Initialize database
init_db() {
    log "Initializing Odoo database..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh init-db
    log "Database initialized successfully!"
}

# Update modules
update_modules() {
    if [ -z "$2" ]; then
        error "Please specify modules to update (e.g., base,web)"
        exit 1
    fi
    
    log "Updating modules: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh update "$2"
    log "Modules updated successfully!"
}

# Install modules
install_modules() {
    if [ -z "$2" ]; then
        error "Please specify modules to install (e.g., sale,purchase)"
        exit 1
    fi
    
    log "Installing modules: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh install "$2"
    log "Modules installed successfully!"
}

# Backup database
backup() {
    log "Creating database backup..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh backup
    log "Backup created successfully!"
}

# Restore database
restore() {
    if [ -z "$2" ]; then
        error "Please specify backup file path"
        exit 1
    fi
    
    log "Restoring database from: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh restore "$2"
    log "Database restored successfully!"
}

# Open Odoo shell
shell() {
    log "Opening Odoo shell..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh shell
}

# Clean up (remove containers, networks, volumes)
clean() {
    warn "This will remove all containers, networks, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log "Cleaning up Docker resources..."
        docker-compose -f $COMPOSE_FILE down -v --remove-orphans
        docker system prune -f
        log "Cleanup completed!"
    else
        info "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    echo -e "${CYAN}Odoo 18.0 Docker Management Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Available commands:${NC}"
    echo "  build                   Build Docker images"
    echo "  start                   Start all services"
    echo "  stop                    Stop all services"
    echo "  restart                 Restart all services"
    echo "  status                  Show services status"
    echo "  logs [SERVICE]          Show logs (all services or specific service)"
    echo "  shell                   Open Odoo shell"
    echo "  exec [COMMAND]          Execute command in Odoo container"
    echo ""
    echo -e "${YELLOW}Database commands:${NC}"
    echo "  init-db                 Initialize Odoo database"
    echo "  update MODULES          Update specified modules"
    echo "  install MODULES         Install specified modules"
    echo "  backup                  Create database backup"
    echo "  restore BACKUP_FILE     Restore database from backup"
    echo ""
    echo -e "${YELLOW}Utility commands:${NC}"
    echo "  ssl                     Generate SSL certificates"
    echo "  clean                   Clean up Docker resources"
    echo "  help                    Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start"
    echo "  $0 logs odoo"
    echo "  $0 install sale,purchase,stock"
    echo "  $0 update base,web"
    echo "  $0 backup"
    echo "  $0 shell"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Edit .env file to customize settings"
    echo "  SSL certificates will be generated automatically"
    echo "  Access Odoo at: https://localhost"
}

# Main command processing
case "$1" in
    build)
        build
        ;;
    start|up)
        start
        ;;
    stop|down)
        stop
        ;;
    restart)
        restart
        ;;
    status|ps)
        status
        ;;
    logs)
        logs "$@"
        ;;
    shell)
        shell
        ;;
    exec)
        exec_odoo "$@"
        ;;
    init-db)
        init_db
        ;;
    update)
        update_modules "$@"
        ;;
    install)
        install_modules "$@"
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$@"
        ;;
    ssl)
        generate_ssl
        ;;
    clean)
        clean
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
