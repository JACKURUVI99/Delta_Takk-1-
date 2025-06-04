#!/bin/bash
# File: subscriptionModel.sh

# Ensure script is run by user, author, or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q '\(g_user\|g_author\)'; then
    echo "This script must be run by a user, author, or root" >&2
    exit 1
fi

USERNAME=$(whoami)
SUBS_FILE="/home/admin/subscriptions.yaml"
USER_DIR="/home/users/$USERNAME"

# Initialize subscriptions.yaml if it doesn't exist
if [ ! -f "$SUBS_FILE" ]; then
    echo "subscriptions: []" > "$SUBS_FILE"
fi

# Function to subscribe to an author
subscribe() {
    local author="$1"
    if [ ! -d "/home/authors/$author" ]; then
        echo "Author $author does not exist" >&2
        exit 1
    fi
    yq e -i ".subscriptions += [{\"user\": \"$USERNAME\", \"author\": \"$author\"}]" "$SUBS_FILE"
    mkdir -p "$USER_DIR/subscribed_blogs"
    ln -sf "/home/authors/$author/public" "$USER_DIR/subscribed_blogs/$author"
    echo "Subscribed to $author"
}

# Function to publish article (public or subscribers-only)
publish_article() {
    local filename="$1"
    local type="$2"
    local author_dir="/home/authors/$USERNAME"
    local file_path="$author_dir/blogs/$filename"

    if [ ! -f "$file_path" ]; then
        echo "File $filename does not exist" >&2
        exit 1
    fi

    # Get category preferences
    echo "Available categories:"
    yq e '.categories' "$author_dir/blogs.yaml"
    echo "Enter category numbers (comma-separated, e.g., 2,1):"
    read -r cat_input
    IFS=',' read -r -a cat_order <<< "$cat_input"

    # Update YAML
    yq e -i ".blogs += [{\"file_name\": \"$filename\", \"publish_status\": true, \"cat_order\": [${cat_input}], \"subscribers_only\": $([ "$type" = "subscribers" ] && echo true || echo false)}]" "$author_dir/blogs.yaml"

    if [ "$type" = "public" ]; then
        ln -sf "$file_path" "$author_dir/public/$filename"
        chmod 640 "$author_dir/public/$filename"
        setfacl -m g:g_user:r "$author_dir/public/$filename"
    else
        # Deliver to subscribers
        subscribers=($(yq e ".subscriptions[] | select(.author == \"$USERNAME\").user" "$SUBS_FILE"))
        for user in "${subscribers[@]}"; do
            if [ -d "/home/users/$user/subscribed_blogs" ]; then
                ln -sf "$file_path" "/home/users/$user/subscribed_blogs/$filename"
                chmod 640 "/home/users/$user/subscribed_blogs/$filename"
                chown "$user:g_user" "/home/users/$user/subscribed_blogs/$filename"
            fi
        done
    fi
    echo "Published $filename as $type"
}

# Main execution
case "$1" in
    subscribe)
        subscribe "$2"
        ;;
    publish-public)
        if [ "$(id -u)" != "0" ] && ! groups | grep -q g_author; then
            echo "Only authors or root can publish" >&2
            exit 1
        fi
        publish_article "$2" "public"
        ;;
    publish-subscribers)
        if [ "$(id -u)" != "0" ] && ! groups | grep -q g_author; then
            echo "Only authors or root can publish" >&2
            exit 1
        fi
        publish_article "$2" "subscribers"
        ;;
    *)
        echo "Usage: $0 {subscribe <author>|publish-public <filename>|publish-subscribers <filename>}" >&2
        exit 1
        ;;
esac
