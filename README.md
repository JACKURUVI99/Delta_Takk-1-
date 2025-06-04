# Blogging Platform Scripts

This project provides a set of Bash scripts to manage a blogging platform, allowing users to create, publish, moderate, and subscribe to blog articles. The scripts are designed to work in `/home/harishannavisamy/Deltask/AI gen Deltaak/` and use YAML files for configuration. The platform supports four roles: admins, authors, moderators, and users, with specific permissions enforced via Linux groups (`g_admin`, `g_author`, `g_mod`, `g_user`). All scripts can be run by `root` or the appropriate group.

## Directory Structure
- **Base Directory**: `/home/harishannavisamy/Deltask/AI gen Deltaak/`
- **Scripts Directory**: `/home/harishannavisamy/Deltask/AI gen Deltaak/scripts/`
- **Configuration Files**:
  - `users.yaml`: Defines admins, users, authors, and moderators.
  - `userpref.yaml`: Stores user preferences for blog assignments.
  - `/home/admin/subscriptions.yaml`: Tracks user subscriptions to authors.
  - `/home/authors/<author>/blogs.yaml`: Manages each author’s blog metadata.
- **Data Directories**:
  - `/home/users/<username>/`: User home directories.
  - `/home/authors/<author>/blogs/`: Author blog files.
  - `/home/authors/<author>/public/`: Published blog symlinks.
  - `/home/mods/<moderator>/`: Moderator directories with symlinks to assigned authors.
  - `/home/users/all_blogs/`: Symlinks to all authors’ public directories.
  - `/home/admin/`: Stores subscriptions and reports.

## Prerequisites
- **System**: Linux (tested on Arch Linux).
- **Dependencies**: `bash`, `yq` (version 4.45.4), `netcat` (for notifications).
- **User**: Must have `root` access for setup and a user account (`harishannavisamy`) with full access preserved.
- **YAML Files**: Ensure `users.yaml` and `userpref.yaml` are in the base directory.

## Setup
1. **Save Scripts**:
   - Place all scripts in `/home/harishannavisamy/Deltask/AI gen Deltaak/scripts/`:
     - `deploy_platform.sh`
     - `initUsers.sh`
     - `manageBlogs.sh`
     - `blogFilter.sh`
     - `userFY.sh`
     - `adminPanel.sh`
     - `subscriptionModel.sh`
     - `ncNotify.sh`
     - `rolePromotion.sh`

2. **Run Setup Script**:
   - Execute as `root`:
     ```bash
     sudo bash /home/harishannavisamy/Deltask/AI\ gen\ Deltaak/scripts/deploy_platform.sh
