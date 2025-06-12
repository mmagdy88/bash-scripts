# 🖥️ Bash Scripts Collection

A personal collection of Bash scripts for managing various infrastructure and server tasks.  
Includes backup automation, service installation, and utility scripts.

---

## 📜 Scripts Included

| Script                            | Purpose / Description                             |
|-----------------------------------|--------------------------------------------------|
| `install_thumbor.sh`              | Installation script for old version of Thumbor on new OS (tested on Ubuntu 24 + Python 2.7.18 + Thumbor 6.7.0). |
| `db_backup_backblaze.sh`          | Backup database and upload to Backblaze.          |
| `dmarc.sh`                        | Manage DMARC records for all domains.             |
| `local_backup.sh`                 | Local server backup script.                       |
| `ms_backup.sh`                    | Legacy backup script.                            |
| `ms_bulkcreateaccounts.sh`        | Bulk account creation utility.                   |
| `ms_installrabbitmq.sh`           | Automated RabbitMQ installation and configuration. |
| `ms_installzookeeper.sh`          | Automated Zookeeper installation and configuration. |
| `ms_remotebackup.sh`              | Remote database backup and cleanup after restore. |
| `query_killer.sh`                 | Kill long-running MySQL queries above a defined threshold (n seconds). |

---

## 🚀 How to Use

### Clone the repo

```bash
git clone https://github.com/mmagdy88/bash-scripts.git
cd bash-scripts