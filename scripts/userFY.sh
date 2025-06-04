#!/bin/bash
# File: userFY.sh

# Ensure script is run by admin or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q g_admin; then
    echo "This script must be run by an admin or root" >&2
    exit 1
fi

USERPREF_FILE="/home/harishannavisamy/Deltask/DELTASK/userpref.yaml"
CONFIG_FILE="/home/harishannavisamy/Deltask/DELTASK/users.yaml"

# Get all users and their preferences
users=($(yq e '.users[].username' "$USERPREF_FILE"))
declare -A user_prefs
for user in "${users[@]}"; do
    pref1=$(yq e ".users[] | select(.username == \"$user\").pref1" "$USERPREF_FILE")
    pref2=$(yq e ".users[] | select(.username == \"$user\").pref2" "$USERPREF_FILE")
    pref3=$(yq e ".users[] | select(.username == \"$user\").pref3" "$USERPREF_FILE")
    user_prefs["$user"]="$pref1,$pref2,$pref3"
done

# Get all blogs
declare -A blog_cats
for author in /home/authors/*; do
    if [ -d "$author" ]; then
        author_name=$(basename "$author")
        blogs_yaml="$author/blogs.yaml"
        if [ -f "$blogs_yaml" ]; then
            blog_count=$(yq e '.blogs | length' "$blogs_yaml")
            for ((i=0; i<blog_count; i++)); do
                filename=$(yq e ".blogs[$i].file_name" "$blogs_yaml")
                if [ "$(yq e ".blogs[$i].publish_status" "$blogs_yaml")" = "true" ]; then
                    cats=($(yq e ".blogs[$i].cat_order[]" "$blogs_yaml" | xargs -I {} yq e ".categories.{}" "$blogs_yaml"))
                    blog_cats["$author_name/$filename"]="${cats[*]}"
                fi
            done
        fi
    fi
done

# Assign blogs to users
declare -A assignments
declare -A blog_counts
for user in "${users[@]}"; do
    IFS=',' read -r -a prefs <<< "${user_prefs[$user]}"
    user_assignments=()
    for blog in "${!blog_cats[@]}"; do
        blog_tags=(${blog_cats[$blog]})
        score=0
        for pref in "${prefs[@]}"; do
            if [[ " ${blog_tags[*]} " =~ " $pref " ]]; then
                ((score++))
            fi
        done
        if [ $score -ge 2 ]; then
            user_assignments+=("$blog:$score")
        fi
    done

    # Sort by score and pick top 3
    sorted_assignments=($(printf '%s\n' "${user_assignments[@]}" | sort -t: -k2 -nr | head -n 3))
    for assignment in "${sorted_assignments[@]}"; do
        blog=${assignment%%:*}
        blog_counts["$blog"]=$((blog_counts["$blog"] + 1))
        assignments["$user"]+="$blog,"
    done
done

# Redistribute to balance assignments
for i in {1..3}; do
    for user in "${users[@]}"; do
        current_count=$(grep -o ',' <<< "${assignments[$user]}" | wc -l)
        if [ $current_count -lt 3 ]; then
            available_blogs=()
            for blog in "${!blog_cats[@]}"; do
                if [ ${blog_counts["$blog"]} -lt 2 ]; then
                    available_blogs+=("$blog")
                fi
            done
            if [ ${#available_blogs[@]} -gt 0 ]; then
                blog=${available_blogs[0]}
                assignments["$user"]+="$blog,"
                blog_counts["$blog"]=$((blog_counts["$blog"] + 1))
            fi
        fi
    done
done

# Write FYI.yaml for each user
for user in "${users[@]}"; do
    FYI_FILE="/home/users/$user/FYI.yaml"
    echo "blogs:" > "$FYI_FILE"
    IFS=',' read -r -a blogs <<< "${assignments[$user]}"
    for blog in "${blogs[@]}"; do
        if [ -n "$blog" ]; then
            author=$(dirname "$blog")
            filename=$(basename "$blog")
            echo "  - author: $author" >> "$FYI_FILE"
            echo "    file_name: $filename" >> "$FYI_FILE"
            ln -sf "/home/authors/$author/public/$filename" "/home/users/$user/$filename"
        fi
    done
    chown "$user:g_user" "$FYI_FILE"
    chmod 600 "$FYI_FILE"
done
