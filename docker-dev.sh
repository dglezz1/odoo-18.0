#!/bin/bash
# Odoo 18.0 Docker Development Management Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

COMPOSE_FILE="docker-compose.dev.yml"
PROJECT_NAME="odoo-dev"

log() {
    echo -e "${GREEN}[ODOO DEV]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed!"
        exit 1
    fi
}

# Build development image
build() {
    log "Building Odoo development image..."
    check_docker
    docker-compose -f $COMPOSE_FILE build --no-cache
    log "Development image built successfully!"
}

# Start development environment
start() {
    log "Starting Odoo development environment..."
    check_docker
    
    # Create custom_addons directory if it doesn't exist
    mkdir -p custom_addons
    
    docker-compose -f $COMPOSE_FILE up -d
    log "Development environment started!"
    
    info "Access URLs:"
    info "  Odoo: http://localhost:8069"
    info "  Database: localhost:5432"
    
    info "Development features enabled:"
    info "  - Auto-reload on file changes"
    info "  - Debug mode"
    info "  - Custom addons directory: ./custom_addons"
}

# Stop development environment
stop() {
    log "Stopping development environment..."
    docker-compose -f $COMPOSE_FILE down
    log "Development environment stopped!"
}

# Show logs
logs() {
    if [ -z "$2" ]; then
        docker-compose -f $COMPOSE_FILE logs -f
    else
        docker-compose -f $COMPOSE_FILE logs -f "$2"
    fi
}

# Execute command in Odoo container
exec_dev() {
    if [ -z "$2" ]; then
        docker-compose -f $COMPOSE_FILE exec odoo bash
    else
        docker-compose -f $COMPOSE_FILE exec odoo "${@:2}"
    fi
}

# Start with debugger
debug() {
    log "Starting Odoo with Python debugger..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh debug
    info "Debugger listening on port 5678"
    info "Connect your IDE debugger to localhost:5678"
}

# Run tests
test() {
    if [ -z "$2" ]; then
        log "Running all tests..."
        docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh test
    else
        log "Running tests for: $2"
        docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh test "$2"
    fi
}

# Create new module
scaffold() {
    if [ -z "$2" ]; then
        echo "Please specify module name"
        exit 1
    fi
    
    log "Creating new module: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh scaffold "$2"
    log "Module created in ./custom_addons/$2"
}

# Install modules
install() {
    if [ -z "$2" ]; then
        echo "Please specify modules to install"
        exit 1
    fi
    
    log "Installing modules: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh install "$2"
}

# Update modules
update() {
    if [ -z "$2" ]; then
        echo "Please specify modules to update"
        exit 1
    fi
    
    log "Updating modules: $2"
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh update "$2"
}

# Initialize database
init_db() {
    log "Initializing development database..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh init-db
}

# Open shell
shell() {
    log "Opening Odoo shell..."
    docker-compose -f $COMPOSE_FILE exec odoo ./entrypoint.sh shell
}

# Clean development environment
clean() {
    echo "This will remove all development containers and volumes. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log "Cleaning development environment..."
        docker-compose -f $COMPOSE_FILE down -v --remove-orphans
        docker system prune -f
        log "Development environment cleaned!"
    fi
}

# Show help
show_help() {
    echo -e "${PURPLE}Odoo 18.0 Development Management${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Environment Commands:${NC}"
    echo "  build                   Build development image"
    echo "  start                   Start development environment"
    echo "  stop                    Stop development environment"
    echo "  restart                 Restart development environment"
    echo "  logs [SERVICE]          Show logs"
    echo "  clean                   Clean all development data"
    echo ""
    echo -e "${YELLOW}Development Commands:${NC}"
    echo "  debug                   Start with Python debugger"
    echo "  shell                   Open Odoo shell"
    echo "  exec [COMMAND]          Execute command in container"
    echo "  test [MODULE]           Run tests"
    echo "  scaffold MODULE         Create new module"
    echo ""
    echo -e "${YELLOW}Module Commands:${NC}"
    echo "  init-db                 Initialize database"
    echo "  install MODULES         Install modules"
    echo "  update MODULES          Update modules"
    echo ""
    echo -e "${YELLOW}Development Features:${NC}"
    echo "  - Auto-reload on file changes"
    echo "  - Debug logging enabled"
    echo "  - Custom addons in ./custom_addons/"
    echo "  - Python debugger support (port 5678)"
    echo "  - Hot-reload templates and assets"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start"
    echo "  $0 scaffold my_module"
    echo "  $0 install sale,purchase"
    echo "  $0 debug"
    echo "  $0 test my_module"
}

# Main command processing
case "$1" in
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop && start
        ;;
    logs)
        logs "$@"
        ;;
    exec)
        exec_dev "$@"
        ;;
    debug)
        debug
        ;;
    test)
        test "$@"
        ;;
    scaffold)
        scaffold "$@"
        ;;
    install)
        install "$@"
        ;;
    update)
        update "$@"
        ;;
    init-db)
        init_db
        ;;
    shell)
        shell
        ;;
    clean)
        clean
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
