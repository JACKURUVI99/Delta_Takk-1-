#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Check if user is root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Check if users.yaml exists in the parent directory
if [ ! -f "$CONFIG_DIR/users.yaml" ]; then
    echo "Error: users.yaml not found in $CONFIG_DIR/"
    exit 1
fi

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed."
    exit 1
fi

# Verify yq version
YQ_VERSION=$(yq --version | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
if [ "$YQ_VERSION" != "v4.10.0" ]; then
    echo "Warning: yq version $YQ_VERSION detected, expected v4.10.0. Script may not work as expected."
fi

# Read users from YAML
mapfile -t admins < <(yq e '.admins[].username' "$CONFIG_DIR/users.yaml")
mapfile -t users < <(yq e '.users[].username' "$CONFIG_DIR/users.yaml")
mapfile -t authors < <(yq e '.authors[].username' "$CONFIG_DIR/users.yaml")
mapfile -t mods < <(yq e '.mods[].username' "$CONFIG_DIR/users.yaml")

# Function to delete user safely
delete_user() {
    local username=$1
    local home_dir=$2

    # Skip harish
    if [ "$username" = "harish" ]; then
        echo "Skipping deletion of user harish"
        return
    fi

    # Check if user exists
    if id "$username" &> /dev/null; then
        userdel -r "$username" 2>/dev/null
        if [ -d "$home_dir" ]; then
            rm -rf "$home_dir"
            echo "Deleted user $username and home directory $home_dir"
        else
            echo "Deleted user $username (no home directory found)"
        fi
    else
        echo "User $username does not exist, skipping"
    fi
}

# Remove admin ACLs
for admin in "${admins[@]}"; do
    if [ "$admin" != "harish" ] && id "$admin" &> /dev/null; then
        setfacl -R -x u:"$admin" /home/users /home/admin /home/authors /home/mods 2>/dev/null
        echo "Removed ACLs for admin $admin"
    fi
done

# Delete admins
for admin in "${admins[@]}"; do
    delete_user "$admin" "/home/admin/$admin"
done

# Delete users
for user in "${users[@]}"; do
    delete_user "$user" "/home/users/$user"
    rm -f "/home/users/$user/all_blogs" 2>/dev/null
done

# Delete authors
for author in "${authors[@]}"; do
    delete_user "$author" "/home/authors/$author"
    rm -f "/home/users/all_blogs/$author" 2>/dev/null
done

# Delete moderators
for mod in "${mods[@]}"; do
    delete_user "$mod" "/home/mods/$mod"
    if [ -d "/home/mods/$mod" ]; then
        rm -rf "/home/mods/$mod"/* 2>/dev/null
    fi
done

# Clean up all_blogs symlinks
if [ -d /home/users/all_blogs ]; then
    find /home/users/all_blogs -type l -delete 2>/dev/null
    echo "Cleaned up symlinks in /home/users/all_blogs"
fi

echo "User deletion and cleanup completed."
