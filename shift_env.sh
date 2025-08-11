#!/bin/bash

# Script to shift staging environments in synup.conf
# Available staging environments: dev1-1, dev1-2, dev2-1, dev2-2, dev3-1, dev5-1

CONFIG_FILE="/opt/homebrew/etc/nginx/servers/synup.conf"
CURRENT_ENV=""

# Available staging environments
STAGING_ENVIRONMENTS=("dev1-1" "dev1-2" "dev2-1" "dev2-2" "dev3-1" "dev5-1")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    # echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1 :${NC}"
    # echo -e "${BLUE}================================${NC}"
}

# Function to detect current staging environment
detect_current_env() {
    if grep -q "server dev[0-9]-[0-9]\.stg\.synup\.com:443;" "$CONFIG_FILE"; then
        CURRENT_ENV=$(grep "server dev[0-9]-[0-9]\.stg\.synup\.com:443;" "$CONFIG_FILE" | sed 's/.*server \(dev[0-9]-[0-9]\)\.stg\.synup\.com:443;.*/\1/')
        print_status "Current staging environment detected: $CURRENT_ENV"
    else
        print_error "Could not detect current staging environment"
        exit 1
    fi
}

# Function to perform the actual environment shift
perform_shift() {
    local target_env="$1"
    local valid=false
    
    for env in "${STAGING_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$target_env" ]]; then
            valid=true
            break
        fi
    done
    
    if [ "$valid" = false ]; then
        print_error "Invalid environment: $target_env"
        print_status "Valid environments: ${STAGING_ENVIRONMENTS[*]}"
        return 1
    fi
    
    if [[ "$target_env" == "$CURRENT_ENV" ]]; then
        print_warning "Already on $target_env"
        return 0
    fi
    
    print_status "Shifting from $CURRENT_ENV to $target_env"
    
    # Update the staging_upstream server
    sed -i.bak "s/server $CURRENT_ENV\.stg\.synup\.com:443;/server $target_env.stg.synup.com:443;/" "$CONFIG_FILE"
    
    # Update the proxy_set_header Host
    sed -i.bak "s/proxy_set_header Host $CURRENT_ENV\.stg\.synup\.com;/proxy_set_header Host $target_env.stg.synup.com;/" "$CONFIG_FILE"
    
    # Remove backup files created by sed
    rm -f "$CONFIG_FILE.bak"
    
    print_status "Successfully shifted to $target_env"
    CURRENT_ENV="$target_env"
    
    # Restart nginx to apply the configuration changes
    print_status "Restarting nginx service..."
    if brew services restart nginx; then
        print_status "Nginx service restarted successfully"
    else
        print_warning "Failed to restart nginx service. You may need to restart it manually."
    fi
}

# Function to show interactive arrow key navigation menu
show_arrow_menu() {
    local selected=0
    local key
    
    # Find current environment index
    for i in "${!STAGING_ENVIRONMENTS[@]}"; do
        if [[ "${STAGING_ENVIRONMENTS[$i]}" == "$CURRENT_ENV" ]]; then
            selected=$i
            break
        fi
    done
    
    # Hide cursor
    tput civis
    
    # Function to display menu
    display_menu() {
        clear
        print_header "Staging Environment Selection (Arrow Keys + Enter)"
        echo ""
        echo "Use ↑↓ arrow keys to navigate, Enter to select, q to quit"
        echo ""
        
        for i in "${!STAGING_ENVIRONMENTS[@]}"; do
            local env="${STAGING_ENVIRONMENTS[$i]}"
            local marker=""
            
            if [[ "$env" == "$CURRENT_ENV" ]]; then
                marker=" (current)"
            fi
            
            if [ $i -eq $selected ]; then
                echo -e "  ${GREEN}▶ $env$marker${NC}"
            else
                echo "    $env$marker"
            fi
        done
        
        echo ""
        echo "Press Enter to select the highlighted environment"
    }
    
    # Main menu loop
    while true; do
        display_menu
        
        # Read single character
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # ESC sequence
                read -rsn2 key
                case "$key" in
                    "[A")  # Up arrow
                        if [ $selected -gt 0 ]; then
                            selected=$((selected - 1))
                        fi
                        ;;
                    "[B")  # Down arrow
                        if [ $selected -lt $((${#STAGING_ENVIRONMENTS[@]} - 1)) ]; then
                            selected=$((selected + 1))
                        fi
                        ;;
                esac
                ;;
            "")  # Enter key
                break
                ;;
            "q"|"Q")  # Quit
                tput cnorm  # Show cursor
                print_status "Operation cancelled."
                return 1
                ;;
        esac
    done
    
    # Show cursor
    tput cnorm
    
    local selected_env="${STAGING_ENVIRONMENTS[$selected]}"
    
    if [[ "$selected_env" == "$CURRENT_ENV" ]]; then
        print_warning "Already on $selected_env"
        return 0
    fi
    
    print_status "Selected environment: $selected_env"
    perform_shift "$selected_env"
}

# Function to show interactive menu for environment selection
show_interactive_menu() {
    print_header "Staging Environment Selection"
    echo ""
    echo "Available staging environments:"
    echo ""
    
    for i in "${!STAGING_ENVIRONMENTS[@]}"; do
        local env="${STAGING_ENVIRONMENTS[$i]}"
        local marker=""
        
        if [[ "$env" == "$CURRENT_ENV" ]]; then
            marker=" (current)"
        fi
        
        echo "  $((i+1)). $env$marker"
    done
    
    echo ""
    echo "0. Cancel"
    echo ""
    
    # Get user input
    read -p "Please select an environment (1-${#envs[@]}): " choice
    
    # Validate input
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid input. Please enter a number."
        return 1
    fi
    
    if [ "$choice" -eq 0 ]; then
        print_status "Operation cancelled."
        return 1
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#STAGING_ENVIRONMENTS[@]}" ]; then
        print_error "Invalid selection. Please choose a number between 1 and ${#STAGING_ENVIRONMENTS[@]}."
        return 1
    fi
    
    local selected_env="${STAGING_ENVIRONMENTS[$((choice-1))]}"
    
    if [[ "$selected_env" == "$CURRENT_ENV" ]]; then
        print_warning "Already on $selected_env"
        return 0
    fi
    
    print_status "Selected environment: $selected_env"
    perform_shift "$selected_env"
}

# Function to show current status
show_status() {
    print_header "Current Staging Environment Status"
    detect_current_env
    echo ""
    echo "Available environments:"
    echo "  ${STAGING_ENVIRONMENTS[*]}"
    echo ""
    echo "Current: $CURRENT_ENV"
    echo ""
    echo "Usage:"
    echo "  $0 <env>         - Shift to specific environment (e.g., $0 dev3-1)"
    echo "  $0 status        - Show current status"
    echo "  $0 menu          - Interactive environment selection (numbered)"
    echo "  $0 arrow         - Interactive environment selection (arrow keys)"
}

# Main script logic
main() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file $CONFIG_FILE not found"
        exit 1
    fi
    
    case "$1" in
        "menu")
            detect_current_env
            show_interactive_menu
            ;;
        "arrow")
            detect_current_env
            show_arrow_menu
            ;;
        "status")
            show_status
            ;;
        *)
            # Check if the argument is a valid staging environment
            local valid_env=false
            for env in "${STAGING_ENVIRONMENTS[@]}"; do
                if [[ "$1" == "$env" ]]; then
                    valid_env=true
                    break
                fi
            done
            
            if [ "$valid_env" = true ]; then
                detect_current_env
                perform_shift "$1"
            else
                show_status
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"
