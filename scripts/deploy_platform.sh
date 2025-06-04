#!/bin/bash
# File: deploy_platform.sh

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Define base directory
BASE_DIR="/home/harishannavisamy/Deltask/DELTASK"
SCRIPTS_DIR="$BASE_DIR/scripts"
CONFIG_DIR="$BASE_DIR"

# Create necessary groups
groupadd -f g_user
groupadd -f g_author
groupadd -f g_mod
groupadd -f g_admin

# Create directories
mkdir -p /home/users /home/authors /home/mods /home/admin /home/users/all_blogs

# Set base permissions
chmod 755 /home/users /home/authors /home/mods /home/admin
chown root:g_admin /home/users /home/authors /home/mods /home/admin

# Ensure harishannavisamy retains access
chown harishannavisamy:harishannavisamy /home/harishannavisamy
chmod 755 /home/harishannavisamy
setfacl -m u:harishannavisamy:rwx $BASE_DIR
setfacl -m u:harishannavisamy:rwx $SCRIPTS_DIR

# Install yq if not already installed
if ! command -v yq &> /dev/null; then
    wget https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
fi

# Add scripts directory to PATH
if ! grep -q "$SCRIPTS_DIR" /etc/environment; then
    echo "PATH=\"$PATH:$SCRIPTS_DIR\"" >> /etc/environment
fi

# Copy scripts to SCRIPTS_DIR and set permissions
SCRIPTS=("initUsers.sh" "manageBlogs.sh" "blogFilter.sh" "userFY.sh" "adminPanel.sh" "subscriptionModel.sh" "ncNotify.sh" "rolePromotion.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        chmod 750 "$SCRIPTS_DIR/$script"
        case $script in
            initUsers.sh|userFY.sh|adminPanel.sh)
                chown root:g_admin "$SCRIPTS_DIR/$script"
                ;;
            manageBlogs.sh)
                chown root:g_author "$SCRIPTS_DIR/$script"
                ;;
            blogFilter.sh)
                chown root:g_mod "$SCRIPTS_DIR/$script"
                ;;
            subscriptionModel.sh|ncNotify.sh)
                chown root:g_user "$SCRIPTS_DIR/$script"
                ;;
            rolePromotion.sh)
                chown root:root "$SCRIPTS_DIR/$script"
                chmod 4750 "$SCRIPTS_DIR/$script"
                ;;
        esac
        # Grant harishannavisamy read/write access
        setfacl -m u:harishannavisamy:rw "$SCRIPTS_DIR/$script"
    fi
done

# Set up sudoers for rolePromotion.sh
echo "%g_user ALL=(root) NOPASSWD: $SCRIPTS_DIR/rolePromotion.sh request" > /etc/sudoers.d/rolePromotion
chmod 440 /etc/sudoers.d/rolePromotion

# Create central subscription file
touch /home/admin/subscriptions.yaml
chown root:g_admin /home/admin/subscriptions.yaml
chmod 660 /home/admin/subscriptions.yaml

# Set up cron job for adminPanel.sh
CRON_SCHEDULE="14 15 * 2,5,8,11 3,6 * $SCRIPTS_DIR/adminPanel.sh report >> /home/admin/admin_report.log 2>&1"
(crontab -l 2>/dev/null | grep -v "$SCRIPTS_DIR/adminPanel.sh") | crontab -
echo "$CRON_SCHEDULE" | crontab -

# Set up cron job for ncNotify.sh
echo "0 * * * * $SCRIPTS_DIR/ncNotify.sh check >> /home/admin/ncNotify.log 2>&1" | crontab -

# Ensure all_blogs is accessible
chown root:g_user /home/users/all_blogs
chmod 755 /home/users/all_blogs

echo "Setup completed successfully."
