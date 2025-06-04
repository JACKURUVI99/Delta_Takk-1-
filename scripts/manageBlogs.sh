#!/bin/bash
# File: manageBlogs.sh

# Ensure script is run by author or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q g_author; then
    echo "This script must be run by an author or root" >&2
    exit 1
fi

USERNAME=$(whoami)
BASE_DIR="/home/authors/$USERNAME"
BLOGS_DIR="$BASE_DIR/blogs"
PUBLIC_DIR="$BASE_DIR/public"
BLOGS_YAML="$BASE_DIR/blogs.yaml"

# Initialize blogs.yaml if it doesn't exist
if [ ! -f "$BLOGS_YAML" ]; then
    echo "categories:
  1: Sports
  2: Cinema
  3: Technology
  4: Travel
  5: Food
  6: Lifestyle
  7: Finance
blogs: []" > "$BLOGS_YAML"
fi

# Function to publish an article
publish_article() {
    local filename="$1"
    local file_path="$BLOGS_DIR/$filename"

    if [ ! -f "$file_path" ]; then
        echo "File $filename does not exist" >&2
        exit 1
    fi

    # Get category preferences
    echo "Available categories:"
    yq e '.categories' "$BLOGS_YAML"
    echo "Enter category numbers (comma-separated, e.g., 2,1):"
    read -r cat_input
    IFS=',' read -r -a cat_order <<< "$cat_input"

    # Validate categories
    for cat in "${cat_order[@]}"; do
        if ! yq e ".categories.$cat" "$BLOGS_YAML" &>/dev/null; then
            echo "Invalid category $cat" >&2
            exit 1
        fi
    done

    # Update YAML
    yq e -i ".blogs += [{\"file_name\": \"$filename\", \"publish_status\": true, \"cat_order\": [${cat_input}]}]" "$BLOGS_YAML"

    # Create symlink and set permissions
    ln -sf "$file_path" "$PUBLIC_DIR/$filename"
    chmod 640 "$file_path"
    chmod 640 "$PUBLIC_DIR/$filename"
    setfacl -m g:g_user:r "$PUBLIC_DIR/$filename"

    echo "Published $filename"
}

# Function to archive an article
archive_article() {
    local filename="$1"
    local file_path="$PUBLIC_DIR/$filename"

    if [ -L "$file_path" ]; then
        rm "$file_path"
        yq e -i ".blogs[] | select(.file_name == \"$filename\").publish_status = false" "$BLOGS_YAML"
        chmod 600 "$BLOGS_DIR/$filename"
        echo "Archived $filename"
    else
        echo "File $filename is not published" >&2
        exit 1
    fi
}

# Function to delete an article
delete_article() {
    local filename="$1"
    local file_path="$BLOGS_DIR/$filename"

    if [ -f "$file_path" ]; then
        rm -f "$file_path" "$PUBLIC_DIR/$filename"
        yq e -i "del(.blogs[] | select(.file_name == \"$filename\"))" "$BLOGS_YAML"
        echo "Deleted $filename"
    else
        echo "File $filename does not exist" >&2
        exit 1
    fi
}

# Function to edit article categories
edit_article() {
    local filename="$1"
    if [ ! -f "$BLOGS_DIR/$filename" ]; then
        echo "File $filename does not exist" >&2
        exit 1
    fi

    echo "Current categories for $filename:"
    yq e ".blogs[] | select(.file_name == \"$filename\").cat_order" "$BLOGS_YAML"
    echo "Available categories:"
    yq e '.categories' "$BLOGS_YAML"
    echo "Enter new category numbers (comma-separated, e.g., 2,1):"
    read -r cat_input
    IFS=',' read -r -a cat_order <<< "$cat_input"

    # Validate categories
    for cat in "${cat_order[@]}"; do
        if ! yq e ".categories.$cat" "$BLOGS_YAML" &>/dev/null; then
            echo "Invalid category $cat" >&2
            exit 1
        fi
    done

    yq e -i ".blogs[] | select(.file_name == \"$filename\").cat_order = [${cat_input}]" "$BLOGS_YAML"
    echo "Updated categories for $filename"
}

# Main execution
case "$1" in
    -p)
        publish_article "$2"
        ;;
    -a)
        archive_article "$2"
        ;;
    -d)
        delete_article "$2"
        ;;
    -e)
        edit_article "$2"
        ;;
    *)
        echo "Usage: $0 {-p|-a|-d|-e} <filename>" >&2
        exit 1
        ;;
esac
