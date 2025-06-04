Blogging Platform Scripts
This project provides a set of Bash scripts to manage a blogging platform, allowing users to create, publish, moderate, and subscribe to blog articles. The scripts are designed to work in /home/harishannavisamy/Deltask/AI gen Deltaak/ and use YAML files for configuration. The platform supports four roles: admins, authors, moderators, and users, with specific permissions enforced via Linux groups (g_admin, g_author, g_mod, g_user). All scripts can be run by root or the appropriate group.
Directory Structure

Base Directory: /home/harishannavisamy/Deltask/AI gen Deltaak/
Scripts Directory: /home/harishannavisamy/Deltask/AI gen Deltaak/scripts/
Configuration Files:
users.yaml: Defines admins, users, authors, and moderators.
userpref.yaml: Stores user preferences for blog assignments.
/home/admin/subscriptions.yaml: Tracks user subscriptions to authors.
/home/authors/<author>/blogs.yaml: Manages each author’s blog metadata.


Data Directories:
/home/users/<username>/: User home directories.
/home/authors/<author>/blogs/: Author blog files.
/home/authors/<author>/public/: Published blog symlinks.
/home/mods/<moderator>/: Moderator directories with symlinks to assigned authors.
/home/users/all_blogs/: Symlinks to all authors’ public directories.
/home/admin/: Stores subscriptions and reports.



Prerequisites

System: Linux (tested on Arch Linux).
Dependencies: bash, yq (version 4.45.4), netcat (for notifications).
User: Must have root access for setup and a user account (harishannavisamy) with full access preserved.
YAML Files: Ensure users.yaml and userpref.yaml are in the base directory.

Setup

Save Scripts:

Place all scripts in /home/harishannavisamy/Deltask/AI gen Deltaak/scripts/:
deploy_platform.sh
initUsers.sh
manageBlogs.sh
blogFilter.sh
userFY.sh
adminPanel.sh
subscriptionModel.sh
ncNotify.sh
rolePromotion.sh




Run Setup Script:

Execute as root:sudo bash /home/harishannavisamy/Deltask/AI\ gen\ Deltaak/scripts/deploy_platform.sh


This script:
Creates groups (g_user, g_author, g_mod, g_admin).
Sets up directories (/home/users, /home/authors, /home/mods, /home/admin, /home/users/all_blogs).
Installs yq if missing.
Adds the scripts directory to the system PATH (/etc/environment).
Sets permissions and ownership for scripts and directories.
Configures cron jobs for adminPanel.sh and ncNotify.sh.
Ensures harishannavisamy retains access.




Verify Setup:

Check PATH:echo $PATH

Ensure /home/harishannavisamy/Deltask/AI gen Deltaak/scripts is included.
Reload environment if needed:source /etc/environment





Scripts Overview
All scripts can be run by root or the specified group. Scripts are located in /home/harishannavisamy/Deltask/AI gen Deltaak/scripts/.

deploy_platform.sh:

Purpose: Initializes the platform (groups, directories, permissions, cron jobs).
Run As: root.
Usage: sudo deploy_platform.sh


initUsers.sh:

Purpose: Creates or updates users from users.yaml, sets up directories, and removes outdated users.
Run As: root or g_admin.
Usage: initUsers.sh
Output: Logs to initUsers.log.


manageBlogs.sh:

Purpose: Allows authors to publish, archive, delete, or edit blog articles.
Run As: root or g_author.
Usage:manageBlogs.sh {-p|-a|-d|-e} <filename>


-p: Publish (prompts for categories).
-a: Archive (unpublishes).
-d: Delete.
-e: Edit categories.




blogFilter.sh:

Purpose: Moderators censor blacklisted words in assigned authors’ blogs, archiving blogs with >5 violations.
Run As: root or g_mod.
Usage: blogFilter.sh


userFY.sh:

Purpose: Assigns blogs to users based on preferences in userpref.yaml.
Run As: root or g_admin.
Usage: userFY.sh


adminPanel.sh:

Purpose: Generates reports on blog reads and category statistics.
Run As: root or g_admin.
Usage: adminPanel.sh report
Cron: Runs at 3:14 PM on Wednesdays and first/last Saturdays of February, May, August, November.


subscriptionModel.sh:

Purpose: Manages user subscriptions and author publishing (public or subscribers-only).
Run As: root, g_user, or g_author.
Usage:subscriptionModel.sh {subscribe <author>|publish-public <filename>|publish-subscribers <filename>}




ncNotify.sh:

Purpose: Sends notifications for new articles and checks user notifications.
Run As: root or g_author (for notify), root (for check via cron).
Usage:ncNotify.sh {notify <filename>|check}


Cron: Runs hourly to check notifications.


rolePromotion.sh:

Purpose: Allows users to request promotion to author and admins to approve/reject.
Run As: root or g_user (for request), root or g_admin (for approve).
Usage:rolePromotion.sh {request|approve}





Testing manageBlogs.sh
To test manageBlogs.sh (as you requested):

Setup:

Ensure ananya is in g_author:groups ananya


Verify test_blog.txt exists:ls /home/authors/ananya/blogs/test_blog.txt

If missing, create it:echo "This is a test blog." > /home/authors/ananya/blogs/test_blog.txt
sudo chown ananya:g_author /home/authors/ananya/blogs/test_blog.txt
sudo chmod 600 /home/authors/ananya/blogs/test_blog.txt




Run Publish:
su - ananya -c "manageBlogs.sh -p test_blog.txt"

Or as root:
sudo manageBlogs.sh -p test_blog.txt

Enter 2,1 (Cinema, Sports) when prompted.

Verify:

Check symlink: ls -l /home/authors/ananya/public/test_blog.txt
Check blogs.yaml: yq e '.blogs' /home/authors/ananya/blogs.yaml
Check permissions: getfacl /home/authors/ananya/public/test_blog.txt


Test Other Commands:

Archive: manageBlogs.sh -a test_blog.txt
Edit: manageBlogs.sh -e test_blog.txt (enter 3,4 for Technology, Travel)
Delete: manageBlogs.sh -d test_blog.txt



Troubleshooting

Command Not Found:
Ensure /home/harishannavisamy/Deltask/AI gen Deltaak/scripts/ is in PATH:export PATH=$PATH:/home/harishannavisamy/Deltask/AI\ gen\ Deltaak/scripts


Or use full path: /home/harishannavisamy/Deltask/AI\ gen\ Deltaak/scripts/manageBlogs.sh


Permission Denied:
Verify script permissions: ls -l /home/harishannavisamy/Deltask/AI\ gen\ Deltaak/scripts/
Re-run deploy_platform.sh if needed.


yq Errors:
Check yq --version (should be 4.45.4).


Logs:
Check initUsers.log, admin_report.log, or ncNotify.log in the base directory or /home/admin.



Notes

The harishannavisamy user retains full access and is not modified.
Netcat notifications require a listener on port 12345.
Scripts are inspired by this GitHub repository but customized for your requirements.
Ensure users.yaml and userpref.yaml are correctly formatted to avoid parsing errors.

