#!/usr/bin/env bash

DIR="/opt/noon"
DOTS="$DIR/dots"
NOON_REPO="Noon_Repo"
NOON_REPO_URL="https://pharmaracist.github.io/Noon_Repo/\$arch"
GITHUB_REPO="https://github.com/PharmaRacist/Noon"

info() { echo "▶ $1"; }
ok() { echo "✓ $1"; }
err() { echo "✗ $1"; }
warn() { echo "! $1"; }

# Add repository to pacman.conf
add_repo() {
    info "Checking Noon_Repo..."
    
    if grep -q "\[$NOON_REPO\]" /etc/pacman.conf; then
        ok "Noon_Repo already configured"
    else
        info "Adding Noon_Repo to pacman.conf..."
        sudo tee -a /etc/pacman.conf > /dev/null << EOF

[$NOON_REPO]
SigLevel = Optional TrustAll
Server = $NOON_REPO_URL
EOF
        ok "Noon_Repo added"
    fi
    
    info "Syncing package database..."
    sudo pacman -Sy
    ok "Repository synced"
}

# Remove repo
remove_repo() {
    info "Removing Noon_Repo from pacman.conf..."
    
    sudo sed -i "/^\[$NOON_REPO\]/,/^Server = /d" /etc/pacman.conf
    
    ok "Noon_Repo removed"
    sudo pacman -Sy
}

# Update from GitHub
update_from_github() {
    info "Checking for updates from GitHub..."
    
    # Check if we're in a git repository
    if [ ! -d "$DIR/.git" ]; then
        warn "Not a git repository"
        return 1
    fi
    
    # Check if git is installed
    if ! command -v git &>/dev/null; then
        warn "git not installed"
        return 1
    fi
    
    # Fetch latest changes
    info "Fetching from $GITHUB_REPO..."
    git -C "$DIR" fetch origin 2>/dev/null || {
        err "Failed to fetch from remote"
        return 1
    }
    
    # Get current and remote commit hashes
    local local_commit=$(git -C "$DIR" rev-parse HEAD 2>/dev/null)
    local remote_commit=$(git -C "$DIR" rev-parse origin/main 2>/dev/null || git -C "$DIR" rev-parse origin/master 2>/dev/null)
    
    if [ -z "$local_commit" ] || [ -z "$remote_commit" ]; then
        err "Failed to get commit information"
        return 1
    fi
    
    # Check if we're behind
    if [ "$local_commit" = "$remote_commit" ]; then
        ok "Already up to date"
        return 1
    fi
    
    # Count commits behind
    local branch=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    local commits_behind=$(git -C "$DIR" rev-list --count HEAD..origin/$branch 2>/dev/null || echo "0")
    
    info "Found $commits_behind new commit(s)"
    
    # Pull updates
    info "Pulling updates..."
    if git -C "$DIR" pull origin "$branch" 2>/dev/null; then
        ok "Updated successfully from GitHub"
        return 0
    else
        err "Failed to pull updates"
        return 1
    fi
}

# Update packages
update_packages() {
    info "Updating Noon packages..."
    
    # Sync databases
    sudo pacman -Sy
    
    # Update noon packages
    local packages=(noon-main noon-nvidia)
    local to_update=()
    
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            to_update+=("$pkg")
        fi
    done
    
    if [ ${#to_update[@]} -eq 0 ]; then
        ok "No Noon packages installed"
        return 0
    fi
    
    sudo pacman -S --needed "${to_update[@]}"
    ok "Packages updated"
}

# Copy dotfiles
copy_dots() {
    info "Installing dotfiles..."
    
    if command -v rsync &>/dev/null; then
        rsync -a --exclude='.git' "$DOTS/" "$HOME/"
    else
        cp -rf "$DOTS/"* "$HOME/" 2>/dev/null
    fi
    
    ok "Dotfiles installed to $HOME"
}

# Remove dotfiles
remove_dots() {
    info "Removing dotfiles..."
    
    for item in "$DOTS"/*; do
        [ -e "$item" ] || continue
        rm -rf "$HOME/$(basename "$item")"
    done
    
    ok "Dotfiles removed"
}

case "${1:-install}" in
    install)
        add_repo
        copy_dots
        echo ""
        ok "Installation complete!"
        echo "   Repository: Noon_Repo"
        echo "   Run: sudo pacman -S noon-main"
        ;;
    
    update)
        echo ""
        if update_from_github; then
            echo ""
            update_packages
            echo ""
            copy_dots
            echo ""
            ok "Update complete!"
        else
            echo ""
            warn "No GitHub updates available"
            echo ""
            update_packages
            echo ""
            ok "Packages updated"
        fi
        ;;
    
    remove)
        remove_dots
        remove_repo
        ;;
    
    *)
        echo "Usage: noon {install|update|remove}"
        echo ""
        echo "Commands:"
        echo "  install  - Add Noon_Repo and install dotfiles"
        echo "  update   - Update from GitHub and upgrade packages"
        echo "  remove   - Remove dotfiles and Noon_Repo"
        exit 1
        ;;
esac
