#!/bin/bash

# Function to check if README.md exists in a directory
check_git() {
    local dir=$1
    if [ -f "$dir/README.md" ]; then
        return 0
    else
        return 1
    fi
}

# Function to download a single dotfile repository
download_dotfile() {
    local folder=$1
    local repo_url=$2
    local temp_dir="temp_$(date +%s)"
    
    # Check if folder already exists with README.md
    if check_git "$folder"; then
        dialog --yesno "$folder already exists (README.md found). Skip downloading?" 6 50
        if [ $? -eq 0 ]; then
            dialog --msgbox "Skipped downloading $folder dotfiles." 6 50
            return 0
        fi
    fi
    
    dialog --infobox "Downloading $folder dotfiles from $repo_url..." 5 50
    sleep 1
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Download the tarball
    if ! curl -L --fail "$repo_url/archive/refs/heads/main.tar.gz" -o "$temp_dir/repo.tar.gz"; then
        dialog --msgbox "Error: Failed to download repository from $repo_url." 6 50
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify tarball is a valid gzip file
    if ! file "$temp_dir/repo.tar.gz" | grep -q "gzip compressed data"; then
        dialog --msgbox "Error: Downloaded file is not a valid gzip tarball." 6 50
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract tarball
    if ! tar -xzf "$temp_dir/repo.tar.gz" -C "$temp_dir" 2>/dev/null; then
        dialog --msgbox "Error: Failed to extract tarball." 6 50
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find the extracted folder
    extracted_folder=$(ls "$temp_dir" | grep -E '.*-main$')
    
    if [ -d "$temp_dir/$extracted_folder" ]; then
        # Create target folder if it doesn't exist
        mkdir -p "$folder"
        
        # Move contents to the target folder
        mv "$temp_dir/$extracted_folder/"* "$folder/" 2>/dev/null || {
            dialog --msgbox "Error: Failed to move contents to $folder." 6 50
            rm -rf "$temp_dir"
            return 1
        }
        
        dialog --msgbox "$folder dotfiles downloaded successfully." 6 50
    else
        dialog --msgbox "Error: Could not find extracted folder in $temp_dir." 6 50
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
}

# Function to show download menu
download_menu() {
    choice=$(dialog --clear --backtitle "Dotfiles Manager" \
        --title "Download Dotfiles" \
        --menu "Select an option:" 15 50 6 \
        1 "Download Neovim dotfiles" \
        2 "Download Kitty dotfiles" \
        3 "Download Tmux dotfiles" \
        4 "Download Bash dotfiles" \
        5 "Download all dotfiles" \
        6 "Back to main menu" \
        2>&1 >/dev/tty)

    case $choice in
        1)
            download_dotfile "neovim" "https://github.com/Miraj13123/Neovim"
            download_menu
            ;;
        2)
            download_dotfile "kitty" "https://github.com/Miraj13123/Kitty"
            download_menu
            ;;
        3)
            download_dotfile "tmux" "https://github.com/Miraj13123/tmux"
            download_menu
            ;;
        4)
            download_dotfile "bash" "https://github.com/Miraj13123/Bash"
            download_menu
            ;;
        5)
            download_dotfile "neovim" "https://github.com/Miraj13123/Neovim"
            download_dotfile "kitty" "https://github.com/Miraj13123/Kitty"
            download_dotfile "tmux" "https://github.com/Miraj13123/tmux"
            download_dotfile "bash" "https://github.com/Miraj13123/Bash"
            download_menu
            ;;
        6)
            clear
            return
            ;;
        *)
            dialog --msgbox "Invalid choice, please try again." 6 50
            download_menu
            ;;
    esac
}

# Function to run installer for a specific tool
run_installer() {
    local dir=$1
    local installer_script="$dir/installer_${dir}_dots.sh"
    
    if [ -f "$installer_script" ]; then
        dialog --infobox "Running installer for $dir..." 5 50
        sleep 1
        if bash "$installer_script"; then
            dialog --msgbox "$dir dotfiles installed successfully." 6 50
        else
            dialog --msgbox "Error: Failed to run installer for $dir." 6 50
            return 1
        fi
    else
        dialog --msgbox "Error: Installer script $installer_script not found!" 6 50
        return 1
    fi
}

# Function to display info
show_info() {
    dialog --msgbox "Dotfiles Installer\n\nThis script manages the installation of dotfiles for Neovim, Kitty, Tmux, and Bash.\nEnsure dotfiles are downloaded before running installation options.\nRepository: https://github.com/Miraj13123/dotfiles\n\nRun remotely with:\ncurl -fsSL https://raw.githubusercontent.com/Miraj13123/dotfiles/main/install.sh | bash" 12 60
}

# Function to display the main menu
show_menu() {
    # Check directory presence for each tool
    local neovim_git=false
    local kitty_git=false
    local tmux_git=false
    local bash_git=false
    
    check_git "neovim" && neovim_git=true
    check_git "kitty" && kitty_git=true
    check_git "tmux" && tmux_git=true
    check_git "bash" && bash_git=true
    
    # Check if all dotfiles are downloaded
    local all_downloaded=true
    if ! $neovim_git || ! $kitty_git || ! $tmux_git || ! $bash_git; then
        all_downloaded=false
    fi

    # Build menu options with status
    local menu_options=(
        0 "Download dotfiles"
        1 "Install all $(if $all_downloaded; then echo ''; else echo '(dotfiles not fully downloaded)'; fi)"
        2 "Install Neovim dots $(if $neovim_git; then echo ''; else echo '(dotfiles not downloaded)'; fi)"
        3 "Install Kitty dots $(if $kitty_git; then echo ''; else echo '(dotfiles not downloaded)'; fi)"
        4 "Install Tmux dots $(if $tmux_git; then echo ''; else echo '(dotfiles not downloaded)'; fi)"
        5 "Install Bash dots $(if $bash_git; then echo ''; else echo '(dotfiles not downloaded)'; fi)"
        6 "Info"
        7 "Exit"
    )

    choice=$(dialog --clear --backtitle "Dotfiles Manager" \
        --title "Main Menu" \
        --menu "Select an option:" 15 60 8 "${menu_options[@]}" \
        2>&1 >/dev/tty)

    case $choice in
        0)
            download_menu
            show_menu
            ;;
        1)
            if $all_downloaded; then
                run_installer "neovim"
                run_installer "kitty"
                run_installer "tmux"
                run_installer "bash"
            else
                dialog --msgbox "Dotfiles aren't fully downloaded. Please download dotfiles to continue." 6 50
            fi
            show_menu
            ;;
        2)
            if $neovim_git; then
                run_installer "neovim"
            else
                dialog --msgbox "Neovim dotfiles aren't available. Please download dotfiles to continue." 6 50
            fi
            show_menu
            ;;
        3)
            if $kitty_git; then
                run_installer "kitty"
            else
                dialog --msgbox "Kitty dotfiles aren't available. Please download dotfiles to continue." 6 50
            fi
            show_menu
            ;;
        4)
            if $tmux_git; then
                run_installer "tmux"
            else
                dialog --msgbox "Tmux dotfiles aren't available. Please download dotfiles to continue." 6 50
            fi
            show_menu
            ;;
        5)
            if $bash_git; then
                run_installer "bash"
            else
                dialog --msgbox "Bash dotfiles aren't available. Please download dotfiles to continue." 6 50
            fi
            show_menu
            ;;
        6)
            show_info
            show_menu
            ;;
        7)
            dialog --msgbox "Exiting Dotfiles Manager." 6 50
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Invalid choice, please try again." 6 50
            show_menu
            ;;
    esac
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install it (e.g., sudo apt install curl)."
    exit 1
fi
if ! command -v tar &> /dev/null; then
    echo "Error: tar is not installed. Please install it (e.g., sudo apt install tar)."
    exit 1
fi
if ! command -v file &> /dev/null; then
    echo "Error: file is not installed. Please install it (e.g., sudo apt install file)."
    exit 1
fi
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog is not installed. Please install it (e.g., sudo apt install dialog)."
    exit 1
fi

# Main execution
clear
show_menu
