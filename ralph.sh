#!/bin/bash
# Ralph Wiggum Loop - Autonomous Development Agent
# Usage: ./ralph.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROMPT_FILE="${PROMPT_FILE:-PROMPT.md}"
MAX_ITERATIONS="${MAX_ITERATIONS:-0}" # 0 = infinite
ITERATION=0

# Print with color
log_info() {
    echo -e "${BLUE}[Ralph]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[Ralph]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[Ralph]${NC} $1"
}

log_error() {
    echo -e "${RED}[Ralph]${NC} $1"
}

# Check if PROMPT.md exists
check_prompt_file() {
    if [[ ! -f "$PROMPT_FILE" ]]; then
        log_error "PROMPT.md not found in current directory!"
        log_error "Please create PROMPT.md with your instructions."
        exit 1
    fi
}

# Check if GitHub Copilot CLI is available
check_copilot_cli() {
    if ! command -v copilot &> /dev/null; then
        log_error "GitHub Copilot CLI not found!"
        log_error "Please install: npm i -g @github/copilot"
        exit 1
    fi
}

# Graceful shutdown handler
shutdown() {
    log_warning ""
    log_warning "Ralph is taking a break... (received SIGINT/SIGTERM)"
    log_info "Completed $ITERATION iterations"
    exit 0
}

trap shutdown SIGINT SIGTERM

# Main loop
main() {
    log_success "════════════════════════════════════════════"
    log_success "  Ralph Wiggum - Autonomous Agent Loop"
    log_success "════════════════════════════════════════════"

    # Pre-flight checks
    check_prompt_file
    check_copilot_cli

    log_info "Prompt file: $PROMPT_FILE"
    log_info "Max iterations: $([ $MAX_ITERATIONS -eq 0 ] && echo 'infinite' || echo $MAX_ITERATIONS)"
    log_info "Press Ctrl+C to stop Ralphhh"
    log_success "════════════════════════════════════════════"
    echo ""

    # The Ralph Loop
    while true; do
        ((ITERATION++)) || true
        
        log_info "────────────────────────────────────────────"
        log_info "Iteration #$ITERATION - $(date '+%Y-%m-%d %H:%M:%S')"
        log_info "────────────────────────────────────────────"
        
        # Feed PROMPT.md to GitHub Copilot CLI with all tools allowed
        PROMPT_CONTENT=$(cat "$PROMPT_FILE")
        if copilot -p "$PROMPT_CONTENT" --allow-all-tools; then
            log_success "Iteration #$ITERATION completed successfully"
        else
            EXIT_CODE=$?
            log_error "Iteration #$ITERATION failed with exit code: $EXIT_CODE"
            log_warning "Ralph encountered an error but will continue..."
        fi
        
        echo ""
        
        # Check if we've hit max iterations
        if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
            log_success "Reached max iterations ($MAX_ITERATIONS). Ralph is done!"
            break
        fi
        
        # Small delay to prevent overwhelming the API
        sleep 2
    done
    
    log_success "Ralph completed $ITERATION iterations. Good job, Ralph!"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Ralph Wiggum Loop - Autonomous Development Agent"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROMPT_FILE             Path to prompt file (default: PROMPT.md)"
    echo "  MAX_ITERATIONS          Max iterations (0=infinite, default: 0)"
    echo ""
    echo "Example:"
    echo "  $0                      # Run infinite loop"
    echo "  MAX_ITERATIONS=5 $0     # Run 5 iterations"
    echo "  PROMPT_FILE=custom.md $0 # Use custom prompt"
    echo ""
    exit 0
fi

main
