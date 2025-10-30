#!/usr/bin/env bash
#
# Replace MASTER_IP with the Master node's IP address
#

set -euo pipefail

############################################
# CONFIG
############################################
MASTER_IP="MASTERNODEIPADDRESS"
BACKUP_DIR="/root/pve_vm_backup"
LOGFILE="/var/log/pve-rejoin.log"
MASTER_USER="root"

############################################
# FUNCTIONS
############################################
log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
}

die() {
    log "ERROR: $*"
    exit 1
}

check_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found."
}

############################################
# PRECHECKS
############################################
if [[ $EUID -ne 0 ]]; then
    die "This script must be run as root."
fi

check_cmd systemctl
check_cmd pvecm
check_cmd pmxcfs
check_cmd mkdir
check_cmd mv
check_cmd rm
check_cmd ssh-keyscan

# sshpass is optional
HAS_SSHPASS=0
if command -v sshpass >/dev/null 2>&1; then
    HAS_SSHPASS=1
fi

if ping -c1 -W2 "$MASTER_IP" >/dev/null 2>&1; then
    log "Master $MASTER_IP is reachable."
else
    log "WARNING: Master $MASTER_IP is NOT reachable by ping. Proceeding anyway."
fi

############################################
# STOP SERVICES
############################################
log "Stopping pve-cluster and corosync..."
systemctl stop pve-cluster corosync || log "Warning: failed to stop one of the services."

############################################
# KILL pmxcfs IF RUNNING
############################################
if pgrep -x pmxcfs >/dev/null 2>&1; then
    log "Killing existing pmxcfs..."
    killall pmxcfs || log "Warning: killall pmxcfs failed, continuing."
else
    log "pmxcfs not running, OK."
fi

############################################
# START pmxcfs IN LOCAL MODE (foreground daemonizes itself)
############################################
log "Starting pmxcfs in local mode..."
pmxcfs -l
sleep 2

if ! pgrep -x pmxcfs >/dev/null 2>&1; then
    die "pmxcfs did not start in local mode."
fi
log "pmxcfs (local) is running."

############################################
# CLEAN corosync.conf
############################################
if [[ -f /etc/pve/corosync.conf ]]; then
    log "Removing existing /etc/pve/corosync.conf ..."
    rm -f /etc/pve/corosync.conf || die "Failed to remove /etc/pve/corosync.conf"
else
    log "/etc/pve/corosync.conf not found, skipping."
fi

############################################
# BACKUP VM/LXC CONFIGS
############################################
log "Ensuring backup dir exists at $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR" || die "Failed to create backup dir $BACKUP_DIR"

QEMU_GLOB="/etc/pve/nodes/*/qemu-server/*"
LXC_GLOB="/etc/pve/nodes/*/lxc/*"

if compgen -G "$QEMU_GLOB" >/dev/null 2>&1; then
    log "Moving VM configs to backup dir..."
    mv $QEMU_GLOB "$BACKUP_DIR"/ || die "Failed to move qemu configs"
else
    log "No VM configs found under /etc/pve/nodes/*/qemu-server/"
fi

if compgen -G "$LXC_GLOB" >/dev/null 2>&1; then
    log "Moving LXC configs to backup dir..."
    mv $LXC_GLOB "$BACKUP_DIR"/ || die "Failed to move lxc configs"
else
    log "No LXC configs found under /etc/pve/nodes/*/lxc/"
fi

############################################
# STOP LOCAL pmxcfs AGAIN (cleanup)
############################################
if pgrep -x pmxcfs >/dev/null 2>&1; then
    log "Stopping local pmxcfs..."
    killall pmxcfs || log "Warning: failed to kill pmxcfs."
fi

############################################
# START pve-cluster
############################################
log "Starting pve-cluster..."
systemctl start pve-cluster || die "Failed to start pve-cluster"

# leave corosync stopped before join
log "Ensuring corosync is stopped before join..."
systemctl stop corosync || log "Warning: corosync stop failed."

############################################
# PRE-ACCEPT SSH HOST KEY (this answers the 'yes' part)
############################################
log "Fetching SSH host key from $MASTER_IP to avoid interactive fingerprint prompt..."
ssh-keyscan -H "$MASTER_IP" >> /root/.ssh/known_hosts 2>/dev/null || log "Warning: ssh-keyscan failed, join may ask for fingerprint."

############################################
# JOIN CLUSTER
############################################
log "About to join cluster at $MASTER_IP ..."

if [[ $HAS_SSHPASS -eq 1 ]]; then
    # Non-interactive join
    read -r -s -p "Enter root password for $MASTER_IP: " MASTER_PASS
    echo
    log "Using sshpass for non-interactive pvecm add ..."
    # pvecm add internally uses ssh; sshpass will inject the password
    # --force is optional; keep it clean
    SSH_ASKPASS_REQUIRE=force \
    sshpass -p "$MASTER_PASS" pvecm add "$MASTER_IP" || die "pvecm add failed."
else
    # Interactive fallback
    log "sshpass not found. Running interactive 'pvecm add $MASTER_IP' now..."
    log "You may be asked for root password on $MASTER_IP."
    pvecm add "$MASTER_IP" || die "pvecm add failed."
fi

log "Join finished. Run 'pvecm status' to confirm."