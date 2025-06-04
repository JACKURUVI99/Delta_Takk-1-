#!/bin/bash
# File: blogFilter.sh

# Ensure script is run by moderator or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q g_mod; then
    echo "This script must be run by a moderator or root" >&2
    exit 1
fi

USERNAME=$(whoami)
MOD_DIR="/home/mods/$USERNAME"
BLACKLIST="$MOD_DIR/blacklist.txt"

# Get assigned authors
AUTHORS=($(ls "$MOD_DIR" | grep -v blacklist.txt))

for author in "${AUTHORS[@]}"; do
    PUBLIC_DIR="/home/authors/$author/public"
    if [ -d "$PUBLIC_DIR" ]; then
        for file in "$PUBLIC_DIR"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                count=0
                line_no=0
                temp_file=$(mktemp)

                while IFS= read -r line; do
                    ((line_no++))
                    new_line="$line"
                    while IFS= read -r word; do
                        word_esc=$(echo "$word" | sed 's/[]\/$*.^|[]/\\&/g')
                        if echo "$line" | grep -i -w "$word_esc" >/dev/null; then
                            echo "Found blacklisted word $word in $filename at line $line_no"
                            ((count++))
                            new_line=$(echo "$new_line" | sed -E "s/\b${word_esc}\b/$(printf '%*s' ${#word} | tr ' ' '*')/gi")
                        fi
                    done < "$BLACKLIST"
                    echo "$new_line" >> "$temp_file"
                done < "$file"

                # Update file content
                mv "$temp_file" "$file"
                chmod 640 "$file"
                setfacl -m g:g_user:r "$file"

                # Check if article should be archived
                if [ $count -gt 5 ]; then
                    echo "Blog $filename is archived due to excessive blacklisted words"
                    yq e -i ".blogs[] | select(.file_name == \"$filename\").publish_status = false" "/home/authors/$author/blogs.yaml"
                    yq e -i ".blogs[] | select(.file_name == \"$filename\").mod_comments = \"found $count blacklisted words\"" "/home/authors/$author/blogs.yaml"
                    rm -f "$PUBLIC_DIR/$filename"
                    rm -f "$MOD_DIR/$author/$filename"
                fi
            fi
        done
    fi
done
