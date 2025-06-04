# Blogging Platform Scripts

This project provides a suite of Bash scripts to manage a blogging platform. It supports four roles: `admins`, `authors`, `moderators`, and `users`, each managed via Linux groups (`g_admin`, `g_author`, `g_mod`, `g_user`). Scripts automate the creation, publishing, moderation, and notification of blogs using YAML-based configurations.

---

## 📁 Directory Structure

```
/home/harishannavisamy/Deltask/DELTASK/
├── scripts/
│   ├── deploy_platform.sh
│   ├── initUsers.sh
│   ├── manageBlogs.sh
│   ├── blogFilter.sh
│   ├── userFY.sh
│   ├── adminPanel.sh
│   ├── subscriptionModel.sh
│   ├── ncNotify.sh
│   └── rolePromotion.sh
├── users.yaml
├── userpref.yaml
/home/
├── users/<username>/            # Users' blog directories
├── authors/<author>/blogs/      # Author draft blogs
├── authors/<author>/public/     # Published blog symlinks
├── authors/<author>/blogs.yaml  # Metadata
├── mods/<moderator>/            # Moderation targets
├── admin/subscriptions.yaml     # User subscriptions
├── users/all_blogs/             # Aggregated public blogs
```

---

## ⚙️ Prerequisites

- OS: Linux (tested on Arch Linux)
- Dependencies:
  - `bash`
  - `yq` (v4.45.4)
  - `netcat` (`nc`) for notifications
- User Permissions:
  - `root` is required for full setup.
  - `harishannavisamy` has read/write access to all scripts via ACL.

---

## 🛠️ Setup

1. **Save all scripts** in:
   ```
   /home/harishannavisamy/Deltask/DELTASK/scripts/
   ```

2. **Run deployment**:
   ```bash
   sudo bash /home/harishannavisamy/Deltask/DELTASK/scripts/deploy_platform.sh
   ```

3. **Verify PATH**:
   ```bash
   echo $PATH
   # Ensure scripts path is present. If not:
   export PATH=$PATH:/home/harishannavisamy/Deltask/DELTASK/scripts
   ```

4. **Check Access Control**:
   ```bash
   getfacl /home/harishannavisamy/Deltask/DELTASK/scripts/manageBlogs.sh
   # Ensure: user:harishannavisamy:rw-
   ```

---

## 📜 Script Overview

| Script               | Role            | Description |
|----------------------|-----------------|-------------|
| deploy_platform.sh   | root            | Sets up groups, directories, ACLs, and crons |
| initUsers.sh         | root/g_admin    | Creates users from `users.yaml` |
| manageBlogs.sh       | root/g_author   | Publish, archive, delete, or edit blogs |
| blogFilter.sh        | root/g_mod      | Censors and archives blogs with violations |
| userFY.sh            | root/g_admin    | Assigns blogs to users based on preferences |
| adminPanel.sh        | root/g_admin    | Generates admin reports |
| subscriptionModel.sh | root/g_user/g_author | Handles subscriptions and blog visibility |
| ncNotify.sh          | root/g_author   | Sends/receives blog notifications |
| rolePromotion.sh     | root/g_user/g_admin | Role upgrade requests and approvals |

---

## 🚀 Usage

### `deploy_platform.sh`

```bash
sudo deploy_platform.sh
```
Initializes directories, groups, and permissions.

---

### `initUsers.sh`

```bash
sudo initUsers.sh
```
Creates or updates users from `users.yaml`.

---

### `manageBlogs.sh`

```bash
manageBlogs.sh {-p|-a|-d|-e} <filename>
```

| Flag | Action       |
|------|--------------|
| -p   | Publish blog |
| -a   | Archive blog |
| -d   | Delete blog  |
| -e   | Edit categories |

**Example:**

```bash
su - ananya -c "manageBlogs.sh -p test_blog.txt"
```

---

### `blogFilter.sh`

```bash
su - moderator -c "blogFilter.sh"
```
Censors blacklisted words. Archives if >5 violations.

---

### `userFY.sh`

```bash
sudo userFY.sh
```
Generates FYI assignments from `userpref.yaml`.

---

### `adminPanel.sh`

```bash
sudo adminPanel.sh report
```
Creates admin reports in `/home/admin/admin_report_*.log`.

---

### `subscriptionModel.sh`

```bash
subscriptionModel.sh subscribe <author>
subscriptionModel.sh publish-public <filename>
subscriptionModel.sh publish-subscribers <filename>
```

---

### `ncNotify.sh`

```bash
ncNotify.sh notify <filename>
ncNotify.sh check
```
Notify readers about new blog posts, or check notifications.

---

### `rolePromotion.sh`

```bash
rolePromotion.sh request     # as user
rolePromotion.sh approve     # as admin
```
Handles role upgrade requests.

---

## 🧪 Testing `manageBlogs.sh`

1. Ensure author:
   ```bash
   groups ananya
   ```

2. Blog file:
   ```bash
   echo "Sample blog content" > /home/authors/ananya/blogs/test_blog.txt
   sudo chown ananya:g_author /home/authors/ananya/blogs/test_blog.txt
   sudo chmod 600 /home/authors/ananya/blogs/test_blog.txt
   ```

3. Run publish:
   ```bash
   su - ananya -c "manageBlogs.sh -p test_blog.txt"
   ```

4. Verify:
   ```bash
   ls -l /home/authors/ananya/public/test_blog.txt
   yq e '.blogs' /home/authors/ananya/blogs.yaml
   ```

---

## 🧩 Troubleshooting

### ❌ `command not found`

- Fix with:
  ```bash
  export PATH=$PATH:/home/harishannavisamy/Deltask/DELTASK/scripts
  ```

### ❌ `Permission denied`

- Check ACL:
  ```bash
  getfacl /home/harishannavisamy/Deltask/DELTASK/scripts/manageBlogs.sh
  ```

- Rerun setup if needed:
  ```bash
  sudo deploy_platform.sh
  ```

### ❌ `yq` not found

- Check version:
  ```bash
  yq --version  # should be 4.45.4
  ```

---

## 📌 Notes

- `harishannavisamy` has `rw-` ACL on all scripts.
- Make sure `users.yaml` and `userpref.yaml` are present and correctly formatted.
- Netcat listener must run on port `12345` for notifications.

---

## 📂 Scripts Available

```bash
ls /home/harishannavisamy/Deltask/DELTASK/scripts/
```

Expected output:

```text
adminPanel.sh
blogFilter.sh
deploy_platform.sh
initUsers.sh
manageBlogs.sh
ncNotify.sh
rolePromotion.sh
subscriptionModel.sh
userFY.sh
```

---

## 📄 License

Internal use only. Custom scripts inspired by open-source utilities.
