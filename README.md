# TERMUX SSH AUTO NOTIFIER

> **Automated SSH monitoring and notification system for Termux**

**Created by:** [AkNG](https://github.com/workforakng)

## 📋 Features

* ✅ **Automatic SSH connection details** via email
* ✅ **IP address change detection** and alerts
* ✅ **Failed SSH login attempt** monitoring
* ✅ **Successful SSH connection** notifications
* ✅ **Battery and temperature** monitoring
* ✅ **CPU and RAM usage** tracking
* ✅ **WiFi network change** detection
* ✅ **Data usage monitoring** (vnstat)
* ✅ **Auto-start** on device boot
* ✅ **Beautiful HTML email** notifications

## ⚙️ Requirements

* Android device with **Termux** installed
* Gmail account with **App Password** enabled
* **Termux:Boot** app (available via F-Droid)
* Root access (*Optional: only required for `vnstatd`*)

## 🚀 Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/workforakng/ssh_termux_auto.git](https://github.com/workforakng/ssh_termux_auto.git)
    cd ssh_termux_auto
    ```

2.  **Run the installer:**
    ```bash
    bash install.sh
    ```

3.  **Configure:**
    Follow the on-screen instructions to set up your email and preferences.

## ⚡ Quick Start

After installation is complete:

1.  **Start all services:**
    ```bash
    ~/scripts/manager.sh
    ```
    *(Choose option 1)*

2.  **Check service status:**
    ```bash
    ~/scripts/manager.sh
    ```
    *(Choose option 3)*

3.  **Test email configuration:**
    ```bash
    ~/scripts/email.sh
    ```

## 📂 Scripts Overview

| Script | Description |
| :--- | :--- |
| `email.sh` | Main email notification script |
| `manager.sh` | Control panel for all services |
| `network_monitor.sh` | Monitors IP address changes |
| `ssh_monitor.sh` | Detects failed SSH login attempts |
| `ssh_success_monitor.sh` | Alerts on successful SSH connections |
| `battery_monitor.sh` | Battery and temperature monitoring |
| `wifi_monitor.sh` | WiFi network change detection |
| `data_usage_monitor.sh` | Data usage tracking |
| `network_quality.sh` | Network quality monitoring |
| `boot/start-ssh-notifier` | Auto-start script for boot |

## 🔧 Configuration

All scripts use configuration data from the following files. Edit these to customize behavior:

* **`~/.msmtprc`**: Contains email settings (SMTP, credentials).
* **`config.sh`**: Contains thresholds and general settings.

## 🔒 Security Notes

* **Never commit real credentials to Git.**
* Use **Gmail App Passwords**, never use your actual account password.
* Keep `.msmtprc` file permissions restricted to `600`.
* Review your `.gitignore` file before pushing changes to a remote repository.

## 📄 License

**MIT License** - Free to use and modify.

## 👤 Author & Support

**AkNG**
* GitHub: [https://github.com/workforakng](https://github.com/workforakng)
* Email: [workforakng@gmail.com](mailto:workforakng@gmail.com)

**Support:**
For issues and questions, please visit the [Issue Tracker](https://github.com/workforakng/ssh_termux_auto/issues).

Option 2: Preview
Here is how the README will look when rendered on GitHub:
TERMUX SSH AUTO NOTIFIER
> Automated SSH monitoring and notification system for Termux
> 
Created by: AkNG
📋 Features
 * ✅ Automatic SSH connection details via email
 * ✅ IP address change detection and alerts
 * ✅ Failed SSH login attempt monitoring
 * ✅ Successful SSH connection notifications
 * ✅ Battery and temperature monitoring
 * ✅ CPU and RAM usage tracking
 * ✅ WiFi network change detection
 * ✅ Data usage monitoring (vnstat)
 * ✅ Auto-start on device boot
 * ✅ Beautiful HTML email notifications
⚙️ Requirements
 * Android device with Termux installed
 * Gmail account with App Password enabled
 * Termux:Boot app (available via F-Droid)
 * Root access (Optional: only required for vnstatd)
🚀 Installation
 * Clone the repository:
   git clone https://github.com/workforakng/ssh_termux_auto.git
cd ssh_termux_auto

 * Run the installer:
   bash install.sh

 * Configure:
   Follow the on-screen instructions to set up your email and preferences.
⚡ Quick Start
After installation is complete:
 * Start all services:
   ~/scripts/manager.sh

   (Choose option 1)
 * Check service status:
   ~/scripts/manager.sh

   (Choose option 3)
 * Test email configuration:
   ~/scripts/email.sh

📂 Scripts Overview
| Script | Description |
|---|---|
| email.sh | Main email notification script |
| manager.sh | Control panel for all services |
| network_monitor.sh | Monitors IP address changes |
| ssh_monitor.sh | Detects failed SSH login attempts |
| ssh_success_monitor.sh | Alerts on successful SSH connections |
| battery_monitor.sh | Battery and temperature monitoring |
| wifi_monitor.sh | WiFi network change detection |
| data_usage_monitor.sh | Data usage tracking |
| network_quality.sh | Network quality monitoring |
| boot/start-ssh-notifier | Auto-start script for boot |
🔧 Configuration
All scripts use configuration data from the following files. Edit these to customize behavior:
 * ~/.msmtprc: Contains email settings (SMTP, credentials).
 * config.sh: Contains thresholds and general settings.
🔒 Security Notes
 * Never commit real credentials to Git.
 * Use Gmail App Passwords, never use your actual account password.
 * Keep .msmtprc file permissions restricted to 600.
 * Review your .gitignore file before pushing changes to a remote repository.
📄 License
MIT License - Free to use and modify.
👤 Author & Support
AkNG
 * GitHub: https://github.com/workforakng
 * Email: workforakng@gmail.com
Support:
For issues and questions, please visit the Issue Tracker.- Use Gmail App Passwords, not your actual password
- Keep .msmtprc permissions at 600
- Review .gitignore before pushing

LICENSE
-------
MIT License - Free to use and modify

AUTHOR
------
AkNG
GitHub: https://github.com/workforakng
Email: workforakng@gmail.com

SUPPORT
-------
For issues and questions:
https://github.com/workforakng/ssh_termux_auto/issues
