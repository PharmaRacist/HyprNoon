#!/usr/bin/env bash

# Config
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS="$DIR/dots"
SETUP_DATA="$DIR/setup_data"
BACKUP="$HOME/.dots_backup_$(date +%Y%m%d_%H%M%S)"
PKGS_FILE="$SETUP_DATA/packages.txt"
NVIDIA_PKGS_FILE="$SETUP_DATA/nvidia_packages.txt"
NVIDIA_PATCH="$SETUP_DATA/setup_nvidia.sh"
GREETER_FILE="$SETUP_DATA/greeter_asci.txt"
SEQUENCE_FILE="$SETUP_DATA/sequence.txt"
GLOBAL_SERVICES_FILE="$SETUP_DATA/global_services.txt"
NVIDIA_SERVICES_FILE="$SETUP_DATA/nvidia_services.txt"
PKGS=()
SERVICES=()
AUTO=false
DO_BACKUP=false
USE_NVIDIA=false
DO_INSTALL_PKGS=false
DO_INSTALL_DOTS=false
DO_ENABLE_SERVICES=false
DO_REMOVE_DOTS=false
DO_DISABLE_SERVICES=false
DO_REMOVE_PKGS=false

# Print functions
info() { echo "▶ $1"; }
ok() { echo "✓ $1"; }
err() { echo "✗ $1"; }
warn() { echo "! $1"; }

# Show greeter
show_greeter() {
    [ -f "$GREETER_FILE" ] && cat "$GREETER_FILE" && echo ""
}

# Show terminal color scheme
show_sequence() {
    if [ -f "$SEQUENCE_FILE" ]; then
        while IFS= read -r line; do
            printf '%b' "$line"
        done < "$SEQUENCE_FILE"
        echo ""
    fi
}

# Sudo keep-alive
sudo_loop() {
    sudo -v
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" || exit
    done 2>/dev/null &
    SUDO_PID=$!
}

cleanup() {
    [ -n "$SUDO_PID" ] && kill "$SUDO_PID" 2>/dev/null
}
trap cleanup EXIT

# Simple yes/no prompt
prompt() {
    local msg="$1"
    local response
    
    read -p "? $msg [y/N]: " -n 1 -r response
    echo
    [[ $response =~ ^[Yy]$ ]]
}

# Collect all user inputs upfront
collect_install_inputs() {
    echo ""
    
    # NVIDIA support
    if [ "$USE_NVIDIA" != true ]; then
        prompt "Do you have an NVIDIA GPU?" && USE_NVIDIA=true
        echo ""
    fi
    
    # Install packages
    prompt "Install packages?" && DO_INSTALL_PKGS=true
    echo ""
    
    # Install dotfiles
    prompt "Install dotfiles?" && DO_INSTALL_DOTS=true
    echo ""
    
    # Enable services
    prompt "Enable and start services?" && DO_ENABLE_SERVICES=true
    echo ""
    
    # Show summary
    echo "NVIDIA: $USE_NVIDIA | Packages: $DO_INSTALL_PKGS | Dotfiles: $DO_INSTALL_DOTS | Services: $DO_ENABLE_SERVICES"
    echo ""
    
    if ! prompt "Proceed?"; then
        info "Cancelled"
        exit 0
    fi
    echo ""
}

# Collect all user inputs for uninstall
collect_uninstall_inputs() {
    echo ""
    
    prompt "Remove dotfiles?" && DO_REMOVE_DOTS=true
    echo ""
    
    prompt "Disable services?" && DO_DISABLE_SERVICES=true
    echo ""
    
    prompt "Remove packages?" && DO_REMOVE_PKGS=true
    echo ""
    
    echo "Remove Dotfiles: $DO_REMOVE_DOTS | Disable Services: $DO_DISABLE_SERVICES | Remove Packages: $DO_REMOVE_PKGS"
    echo ""
    
    if ! prompt "Proceed?"; then
        info "Cancelled"
        exit 0
    fi
    echo ""
}

# Load packages
load_packages() {
    [ ! -f "$PKGS_FILE" ] && err "packages.txt not found" && exit 1
    
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -n "$line" ] && PKGS+=("$line")
    done < "$PKGS_FILE"
    
    # Load NVIDIA packages if requested
    if [ "$USE_NVIDIA" = true ]; then
        if [ -f "$NVIDIA_PKGS_FILE" ]; then
            while IFS= read -r line; do
                line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
                [ -n "$line" ] && PKGS+=("$line")
            done < "$NVIDIA_PKGS_FILE"
        else
            warn "nvidia_packages.txt not found"
        fi
    fi
    
    [ ${#PKGS[@]} -eq 0 ] && err "No packages found" && exit 1
}

# Load services
load_services() {
    SERVICES=()
    
    # Load global services
    if [ -f "$GLOBAL_SERVICES_FILE" ]; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -n "$line" ] && SERVICES+=("$line")
        done < "$GLOBAL_SERVICES_FILE"
    fi
    
    # Load NVIDIA services if requested
    if [ "$USE_NVIDIA" = true ]; then
        if [ -f "$NVIDIA_SERVICES_FILE" ]; then
            while IFS= read -r line; do
                line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
                [ -n "$line" ] && SERVICES+=("$line")
            done < "$NVIDIA_SERVICES_FILE"
        fi
    fi
}

# Ensure yay is installed
ensure_yay() {
    command -v yay &>/dev/null && return 0
    
    info "Installing yay..."
    
    sudo pacman -S --needed --noconfirm base-devel git
    local tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay" --depth 1 -q
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    
    command -v yay &>/dev/null && ok "yay installed" || { err "yay install failed"; return 1; }
}

# Install packages
install_pkgs() {
    info "Checking packages..."
    ensure_yay || { warn "Continuing without yay"; return; }
    
    local to_install=()
    local not_found=()
    
    for pkg in "${PKGS[@]}"; do
        pacman -Q "$pkg" &>/dev/null && continue
        
        if pacman -Si "$pkg" &>/dev/null || yay -Si "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        else
            not_found+=("$pkg")
        fi
    done
    
    [ ${#not_found[@]} -gt 0 ] && err "Not found: ${not_found[*]}"
    [ ${#to_install[@]} -eq 0 ] && ok "All packages installed" && return
    
    info "Installing ${#to_install[@]} package(s)..."
    
    local ok=0
    local fail=()
    
    for pkg in "${to_install[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            sudo pacman -S --needed --noconfirm "$pkg" && ((ok++)) || fail+=("$pkg")
        else
            yay -S --needed --noconfirm "$pkg" && ((ok++)) || fail+=("$pkg")
        fi
    done
    
    ok "Installed $ok packages"
    [ ${#fail[@]} -gt 0 ] && err "Failed: ${fail[*]}"
}

# Run NVIDIA patch
run_nvidia_patch() {
    [ "$USE_NVIDIA" != true ] && return 0
    
    if [ -f "$NVIDIA_PATCH" ]; then
        info "Running NVIDIA patch..."
        chmod +x "$NVIDIA_PATCH"
        bash "$NVIDIA_PATCH" && ok "NVIDIA patch complete" || err "NVIDIA patch failed"
    fi
}

# Enable and start services
manage_services() {
    [ ${#SERVICES[@]} -eq 0 ] && info "No services to manage" && return
    
    info "Managing ${#SERVICES[@]} service(s)..."
    
    local enabled=0
    local started=0
    local failed_enable=()
    local failed_start=()
    local not_found=()
    
    for service in "${SERVICES[@]}"; do
        # Check if service exists
        if ! systemctl list-unit-files "$service" &>/dev/null && \
           ! systemctl list-unit-files "$service.service" &>/dev/null; then
            not_found+=("$service")
            continue
        fi
        
        # Normalize service name
        local svc="$service"
        [[ ! "$svc" =~ \.service$ ]] && svc="${svc}.service"
        
        # Enable service
        sudo systemctl enable "$svc" &>/dev/null && ((enabled++)) || failed_enable+=("$service")
        
        # Start service
        sudo systemctl start "$svc" &>/dev/null && ((started++)) || failed_start+=("$service")
    done
    
    ok "Enabled $enabled, started $started service(s)"
    [ ${#not_found[@]} -gt 0 ] && warn "Not found: ${not_found[*]}"
    [ ${#failed_enable[@]} -gt 0 ] && warn "Failed to enable: ${failed_enable[*]}"
    [ ${#failed_start[@]} -gt 0 ] && warn "Failed to start: ${failed_start[*]}"
}

# Disable and stop services
disable_services() {
    [ ${#SERVICES[@]} -eq 0 ] && return
    
    info "Disabling ${#SERVICES[@]} service(s)..."
    
    local stopped=0
    local disabled=0
    
    for service in "${SERVICES[@]}"; do
        local svc="$service"
        [[ ! "$svc" =~ \.service$ ]] && svc="${svc}.service"
        
        systemctl is-active --quiet "$svc" && sudo systemctl stop "$svc" 2>/dev/null && ((stopped++))
        systemctl is-enabled --quiet "$svc" 2>/dev/null && sudo systemctl disable "$svc" 2>/dev/null && ((disabled++))
    done
    
    ok "Stopped $stopped, disabled $disabled service(s)"
}

# Copy dotfiles
copy_dots() {
    info "Copying dotfiles..."
    [ ! -d "$DOTS" ] && err "dots/ not found" && exit 1
    
    local copied=0
    
    if command -v rsync &>/dev/null; then
        rsync -a --exclude='.git' "$DOTS/" "$HOME/"
        copied=$(find "$DOTS" -type f | wc -l)
    else
        shopt -s dotglob nullglob
        for item in "$DOTS"/*; do
            [ -e "$item" ] || continue
            cp -rf "$item" "$HOME/"
            if [ -d "$item" ]; then
                copied=$((copied + $(find "$item" -type f | wc -l)))
            else
                ((copied++))
            fi
        done
        shopt -u dotglob nullglob
    fi
    
    ok "Copied $copied files"
}

# Update from git repository
update_from_git() {
    info "Checking for updates..."
    
    # Check if we're in a git repository
    if [ ! -d "$DIR/.git" ]; then
        warn "Not a git repository, skipping update check"
        return 1
    fi
    
    # Check if git is installed
    if ! command -v git &>/dev/null; then
        warn "git not installed, skipping update check"
        return 1
    fi
    
    # Fetch latest changes
    info "Fetching from github.com/pharmaracist/hyprnoon..."
    git -C "$DIR" fetch origin 2>/dev/null || {
        warn "Failed to fetch from remote"
        return 1
    }
    
    # Get current and remote commit hashes
    local local_commit=$(git -C "$DIR" rev-parse HEAD 2>/dev/null)
    local remote_commit=$(git -C "$DIR" rev-parse origin/main 2>/dev/null || git -C "$DIR" rev-parse origin/master 2>/dev/null)
    
    if [ -z "$local_commit" ] || [ -z "$remote_commit" ]; then
        warn "Failed to get commit information"
        return 1
    fi
    
    # Check if we're behind
    if [ "$local_commit" = "$remote_commit" ]; then
        ok "Already up to date"
        return 0
    fi
    
    # Count commits behind
    local commits_behind=$(git -C "$DIR" rev-list --count HEAD..origin/main 2>/dev/null || git -C "$DIR" rev-list --count HEAD..origin/master 2>/dev/null)
    
    info "Found $commits_behind new commit(s)"
    echo ""
    
    if ! prompt "Pull updates?"; then
        info "Update skipped"
        return 1
    fi
    
    # Pull updates
    info "Pulling updates..."
    if git -C "$DIR" pull origin main 2>/dev/null || git -C "$DIR" pull origin master 2>/dev/null; then
        ok "Updated successfully"
        return 0
    else
        err "Failed to pull updates"
        return 1
    fi
}

# Remove dotfiles
remove_dots() {
    info "Removing dotfiles..."
    [ ! -d "$DOTS" ] && err "dots/ not found" && exit 1
    
    local removed=0
    
    shopt -s dotglob nullglob
    for item in "$DOTS"/*; do
        [ -e "$item" ] || continue
        local name=$(basename "$item")
        local dst="$HOME/$name"
        
        if [ -d "$item" ]; then
            removed=$((removed + $(find "$dst" -type f 2>/dev/null | wc -l)))
            rm -rf "$dst" 2>/dev/null
        elif [ -f "$dst" ]; then
            rm -f "$dst" && ((removed++))
        fi
    done
    shopt -u dotglob nullglob
    
    ok "Removed $removed files"
}

# Uninstall packages
uninstall_pkgs() {
    local to_remove=()
    for pkg in "${PKGS[@]}"; do
        pacman -Q "$pkg" &>/dev/null && to_remove+=("$pkg")
    done
    
    [ ${#to_remove[@]} -eq 0 ] && info "No packages to remove" && return
    
    info "Removing ${#to_remove[@]} package(s)..."
    sudo pacman -Rs --noconfirm "${to_remove[@]}"
    ok "Packages removed"
}

# Main
main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--auto) 
                AUTO=true
                USE_NVIDIA=false
                DO_INSTALL_PKGS=true
                DO_INSTALL_DOTS=true
                DO_ENABLE_SERVICES=true
                shift 
                ;;
            --nvidia) USE_NVIDIA=true; shift ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS] COMMAND"
                echo ""
                echo "Commands:"
                echo "  install    Install packages, dotfiles, and enable services"
                echo "  uninstall  Remove dotfiles, disable services, and remove packages"
                echo "  update     Update dotfiles only"
                echo ""
                echo "Options:"
                echo "  -a, --auto    Auto mode (prompts shown)"
                echo "  --nvidia      Enable NVIDIA support"
                echo "  -h, --help    Show help"
                exit 0
                ;;
            install|uninstall|update)
                CMD=$1; shift ;;
            *)
                err "Unknown: $1"
                exit 1
                ;;
        esac
    done
    
    [ -z "$CMD" ] && err "No command specified" && exit 1
    
    show_greeter
    show_sequence
    
    # Collect all user inputs at the start
    case $CMD in
        install)
            collect_install_inputs
            ;;
        uninstall)
            collect_uninstall_inputs
            ;;
        update)
            update_from_git && copy_dots
            echo ""
            ok "Update complete!"
            ;;
    esac
    
    # Start execution
    sudo_loop
    
    # Always load packages and services lists (needed for service management)
    if [ "$DO_INSTALL_PKGS" = true ] || [ "$DO_REMOVE_PKGS" = true ]; then
        load_packages
    fi
    
    if [ "$DO_ENABLE_SERVICES" = true ] || [ "$DO_DISABLE_SERVICES" = true ]; then
        load_services
    fi
    
    if [ ${#PKGS[@]} -gt 0 ] || [ ${#SERVICES[@]} -gt 0 ]; then
        info "Loaded ${#PKGS[@]} package(s), ${#SERVICES[@]} service(s)"
        echo ""
    fi
    
    # Execute based on collected inputs
    case $CMD in
        install)
            [ "$DO_INSTALL_PKGS" = true ] && install_pkgs && run_nvidia_patch
            [ "$DO_INSTALL_DOTS" = true ] && copy_dots
            [ "$DO_ENABLE_SERVICES" = true ] && manage_services
            echo ""
            ok "Installation complete!"
            ;;
        uninstall)
            [ "$DO_REMOVE_DOTS" = true ] && remove_dots
            [ "$DO_DISABLE_SERVICES" = true ] && disable_services
            [ "$DO_REMOVE_PKGS" = true ] && uninstall_pkgs
            echo ""
            ok "Uninstallation complete!"
            ;;
        update)
            copy_dots
            echo ""
            ok "Update complete!"
            ;;
    esac
}

main "$@"