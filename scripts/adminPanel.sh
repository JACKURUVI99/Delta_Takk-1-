#!/bin/bash
# File: adminPanel.sh

# Ensure script is run by admin or root
if [ "$(id -u)" != "0" ] && ! groups | grep -q g_admin; then
    echo "This script must be run by an admin or root" >&2
    exit 1
fi

REPORT_FILE="/home/admin/admin_report_$(date +%F_%H%M%S).log"
touch "$REPORT_FILE"
chmod 660 "$REPORT_FILE"
chown root:g_admin "$REPORT_FILE"

# Track reads
track_reads() {
    declare -A read_counts
    for user_dir in /home/users/*; do
        if [ -d "$user_dir" ]; then
            user=$(basename "$user_dir")
            for file in "$user_dir"/*.txt; do
                if [ -f "$file" ] && [ -L "$file" ]; then
                    blog=$(readlink -f "$file")
                    read_counts["$blog"]=$((read_counts["$blog"] + 1))
                fi
            done
        fi
    done

    # Write top 3 most read
    echo "Top 3 Most Read Articles:" >> "$REPORT_FILE"
    printf '%s\n' "${!read_counts[@]}" | while read -r blog; do
        echo "$blog:${read_counts[$blog]}"
    done | sort -t: -k2 -nr | head -n 3 | while read -r line; do
        blog=${line%%:*}
        count=${line##*:}
        author=$(basename "$(dirname "$(dirname "$blog")")")
        filename=$(basename "$blog")
        echo "$author/$filename: $count reads" >> "$REPORT_FILE"
    done
}

# Summarize blog activity
summarize_blogs() {
    declare -A pub_counts del_counts
    for author_dir in /home/authors/*; do
        if [ -d "$author_dir" ]; then
            author=$(basename "$author_dir")
            blogs_yaml="$author_dir/blogs.yaml"
            if [ -f "$blogs_yaml" ]; then
                blog_count=$(yq e '.blogs | length' "$blogs_yaml")
                for ((i=0; i<blog_count; i++)); do
                    filename=$(yq e ".blogs[$i].file_name" "$blogs_yaml")
                    status=$(yq e ".blogs[$i].publish_status" "$blogs_yaml")
                    cats=($(yq e ".blogs[$i].cat_order[]" "$blogs_yaml" | xargs -I {} yq e ".categories.{}" "$blogs_yaml"))
                    if [ "$status" = "true" ]; then
                        for cat in "${cats[@]}"; do
                            pub_counts["$cat"]=$((pub_counts["$cat"] + 1))
                        done
                    elif [ ! -f "$author_dir/blogs/$filename" ]; then
                        for cat in "${cats[@]}"; do
                            del_counts["$cat"]=$((del_counts["$cat"] + 1))
                        done
                    fi
                done
            fi
        fi
    done

    echo "Published Articles by Category:" >> "$REPORT_FILE"
    for cat in "${!pub_counts[@]}"; do
        echo "$cat: ${pub_counts[$cat]}" >> "$REPORT_FILE"
    done
    echo "Deleted Articles by Category:" >> "$REPORT_FILE"
    for cat in "${!del_counts[@]}"; do
        echo "$cat: ${del_counts[$cat]}" >> "$REPORT_FILE"
    done
}

# Main execution
case "$1" in
    report)
        echo "Generating report at $(date)" >> "$REPORT_FILE"
        track_reads
        summarize_blogs
        echo "Report generated: $REPORT_FILE"
        ;;
    *)
        echo "Usage: $0 report" >&2
        exit 1
        ;;
esac
