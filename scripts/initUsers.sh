#!/bin/bash
# File: initUsers.sh

# Ensure script is run by admin or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q g_admin; then
    echo "This script must be run by an admin or root" >&2
    exit 1
fi

CONFIG_FILE="/home/harishannavisamy/Deltask/DELTASK/users.yaml"
LOG_FILE="/home/harishannavisamy/Deltask/DELTASK/scripts/initUsers.log"

# Function to process users
process_users() {
    local role=$1
    local group=$2
    local base_dir=$3
    local usernames=($(yq e ".$role[].username" "$CONFIG_FILE"))

    for username in "${usernames[@]}"; do
        if ! id "$username" &>/dev/null; then
            useradd -m -d "$base_dir/$username" -g "$group" -s /bin/bash "$username"
            echo "Created $role user $username" >> "$LOG_FILE"
        else
            usermod -g "$group" "$username"
            echo "Updated group for $role user $username" >> "$LOG_FILE"
        fi

        # Set directory permissions
        chown "$username:$group" "$base_dir/$username"
        chmod 700 "$base_dir/$username"

        # Additional setup for authors
        if [ "$role" = "authors" ]; then
            mkdir -p "$base_dir/$username/blogs" "$base_dir/$username/public"
            chown "$username:$group" "$base_dir/$username/blogs" "$base_dir/$username/public"
            chmod 700 "$base_dir/$username/blogs"
            chmod 750 "$base_dir/$username/public"
            touch "$base_dir/$username/blogs.yaml"
            chown "$username:$group" "$base_dir/$username/blogs.yaml"
            chmod 600 "$base_dir/$username/blogs.yaml"
            ln -sf "$base_dir/$username/public" "/home/users/all_blogs/$username"
        fi
    done
}

# Process moderators and their author assignments
process_mods() {
    local mod_count=$(yq e '.mods | length' "$CONFIG_FILE")
    for ((i=0; i<mod_count; i++)); do
        local username=$(yq e ".mods[$i].username" "$CONFIG_FILE")
        local mod_dir="/home/mods/$username"

        if ! id "$username" &>/dev/null; then
            useradd -m -d "$mod_dir" -g g_mod -s /bin/bash "$username"
            echo "Created mod $username" >> "$LOG_FILE"
        else
            usermod -g g_mod "$username"
            echo "Updated group for mod $username" >> "$LOG_FILE"
        fi

        chown "$username:g_mod" "$mod_dir"
        chmod 700 "$mod_dir"

        # Create blacklist.txt
        touch "$mod_dir/blacklist.txt"
        chown "$username:g_mod" "$mod_dir/blacklist.txt"
        chmod 600 "$mod_dir/blacklist.txt"
        echo -e "damn\nhell\ncrap" > "$mod_dir/blacklist.txt"

        # Set up symlinks for assigned authors
        local authors=($(yq e ".mods[$i].authors[]" "$CONFIG_FILE"))
        for author in "${authors[@]}"; do
            local author_public="/home/authors/$author/public"
            if [ -d "$author_public" ]; then
                ln -sf "$author_public" "$mod_dir/$author"
                chmod -R g+rw "$author_public"
                setfacl -m g:g_mod:rw "$author_public"
            fi
        done
    done
}

# Remove users not in YAML
remove_old_users() {
    local role=$1
    local base_dir=$2
    local group=$3
    local yaml_usernames=($(yq e ".$role[].username" "$CONFIG_FILE"))
    local system_users=($(ls "$base_dir"))

    for user in "${system_users[@]}"; do
        if [[ ! " ${yaml_usernames[@]} " =~ " $user " && "$user" != "harishannavisamy" ]]; then
            deluser --quiet "$user" "$group" 2>/dev/null
            echo "Removed $role $user from group $group" >> "$LOG_FILE"
        fi
    done
}

# Main execution
echo "Starting user initialization at $(date)" >> "$LOG_FILE"

# Process each role
process_users "admins" "g_admin" "/home/admin"
process_users "users" "g_user" "/home/users"
process_users "authors" "g_author" "/home/authors"
process_mods

# Remove old users
remove_old_users "admins" "/home/admin" "g_admin"
remove_old_users "users" "/home/users" "g_user"
remove_old_users "authors" "/home/authors" "g_author"
remove_old_users "mods" "/home/mods" "g_mod"

# Set admin access to all directories
setfacl -R -m g:g_admin:rwx /home/users /home/authors /home/mods

# Ensure all_blogs permissions
chmod 755 /home/users/all_blogs
chown root:g_user /home/users/all_blogs

echo "User initialization completed at $(date)" >> "$LOG_FILE"
