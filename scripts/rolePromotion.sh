#!/bin/bash
# File: rolePromotion.sh

# Function to request promotion
request_promotion() {
    local username="$1"
    REQUESTS_FILE="/home/admin/requests.yaml"

    if [ ! -f "$REQUESTS_FILE" ]; then
        echo "requests: []" > "$REQUESTS_FILE"
        chown root:g_admin "$REQUESTS_FILE"
        chmod 660 "$REQUESTS_FILE"
    fi

    if yq e ".requests[] | select(.username == \"$username\")" "$REQUESTS_FILE" >/dev/null; then
        echo "Promotion request already exists for $username" >&2
        exit 1
    fi

    yq e -i ".requests += [{\"username\": \"$username\"}]" "$REQUESTS_FILE"
    echo "Promotion request submitted for $username"
}

# Function to approve or reject requests
manage_requests() {
    REQUESTS_FILE="/home/admin/requests.yaml"
    if [ ! -f "$REQUESTS_FILE" ]; then
        echo "No pending requests"
        exit 0
    fi

    requests=($(yq e '.requests[].username' "$REQUESTS_FILE"))
    if [ ${#requests[@]} -eq 0 ]; then
        echo "No pending requests"
        exit 0
    fi

    for username in "${requests[@]}"; do
        echo "Approve promotion for $username? (y/n)"
        read -r response
        if [ "$response" = "y" ]; then
            # Move user directory and update group
            mv "/home/users/$username" "/home/authors/$username"
            usermod -g g_author "$username"
            mkdir -p "/home/authors/$username/blogs" "/home/authors/$username/public"
            chown "$username:g_author" "/home/authors/$username" "/home/authors/$username/blogs" "/home/authors/$username/public"
            chmod 700 "/home/authors/$username/blogs"
            chmod 750 "/home/authors/$username/public"
            touch "/home/authors/$username/blogs.yaml"
            chown "$username:g_author" "/home/authors/$username/blogs.yaml"
            chmod 600 "/home/authors/$username/blogs.yaml"
            echo "categories:
  1: Sports
  2: Cinema
  3: Technology
  4: Travel
  5: Food
  6: Lifestyle
  7: Finance
blogs: []" > "/home/authors/$username/blogs.yaml"
            ln -sf "/home/authors/$username/public" "/home/users/all_blogs/$username"
            echo "Approved promotion for $username"
        fi
        yq e -i "del(.requests[] | select(.username == \"$username\"))" "$REQUESTS_FILE"
    done
}

# Main execution
case "$1" in
    request)
        if [ "$(id -u)" != "0" ] && ! groups | grep -q g_user; then
            echo "Only users or root can request promotion" >&2
            exit 1
        fi
        request_promotion "$USERNAME"
        ;;
    approve)
        if [ "$(id -u)" != "0" ] && ! groups | grep -q g_admin; then
            echo "Only admins or root can approve requests" >&2
            exit 1
        fi
        manage_requests
        ;;
    *)
        echo "Usage: $0 {request|approve}" >&2
        exit 1
        ;;
esac
