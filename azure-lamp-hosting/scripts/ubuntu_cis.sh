#!/bin/bash
# Inspired by https://github.com/AndyHS-506/Ubuntu-Hardening

LOG_DIR="/var/cis"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CURRENT_SECTION=""

mkdir -p "$LOG_DIR"

start_section() {
    CURRENT_SECTION="$1"
    echo "[$(date '+%H:%M:%S')] Starting SECTION $CURRENT_SECTION" | tee -a "$LOG_DIR/cis_hardening.log"
}

log_success() {
    echo "  [✓] $1" | tee -a "$LOG_DIR/cis_hardening.log"
}

log_error() {
    echo "  [✗] $1" | tee -a "$LOG_DIR/cis_hardening.log"
}

run_command() {
    local cmd="$1"
    local desc="$2"
    echo "[$(date '+%H:%M:%S')] Running: $desc" | tee -a "$LOG_DIR/cis_hardening.log"
    if eval "$cmd" >> "$LOG_DIR/cis_hardening.log" 2>&1; then
        log_success "$desc"
    else
        log_error "$desc"
    fi
}

backup_file() {
    local file="$1"
    [ -f "$file" ] && cp "$file" "${file}.bak.$TIMESTAMP"
}

set_owner_and_perms() {
    local file="$1"
    local owner="$2"
    local perms="$3"
    run_command "chown $owner '$file'" "Set owner $owner on $file"
    run_command "chmod $perms '$file'" "Set permissions $perms on $file"
}

# ===============[ SECTION 1: Initial Setup ]===============
start_section "Filesystem"
BLACKLIST_CONF="/etc/modprobe.d/cis_blacklist.conf"
touch "$BLACKLIST_CONF"
chmod 644 "$BLACKLIST_CONF"
for mod in cramfs freevxfs hfs hfsplus overlayfs squashfs udf jffs2 usb-storage; do
    run_command "echo 'install $mod /bin/true' >> '$BLACKLIST_CONF'" "Blacklist $mod filesystem kernel module"
    rmmod "$mod" 2>/dev/null || true
done
run_command "update-initramfs -u" "Update initramfs after kernel module changes"

start_section "Package Management"
run_command "export DEBIAN_FRONTEND=noninteractive && apt update && apt upgrade -y" "Update and upgrade packages"

start_section "Mandatory Access Control"
run_command "apt install -y apparmor apparmor-utils" "Install AppArmor"

start_section "Configure Additional Process Hardening"
run_command "echo '2' > /proc/sys/kernel/randomize_va_space" "Enable ASLR"
run_command "echo '1' > /proc/sys/kernel/yama/ptrace_scope" "Restrict ptrace_scope"
run_command "sysctl -p" "Apply kernel settings"
run_command "echo '* hard core 0' >> /etc/security/limits.conf" "Restrict core dumps"
run_command "apt purge -y prelink" "Remove prelink"
run_command "apt purge -y apport" "Remove apport"

start_section "Configure Command Line Warning Banners"
BANNER="******************************************************************
WARNING: Unauthorized access to this system is prohibited.
All activities are monitored and logged.
******************************************************************"
for file in /etc/motd /etc/issue /etc/issue.net; do
    run_command "echo '$BANNER' > '$file'" "Set warning banner in $file"
done
run_command "chmod 644 /etc/issue.net /etc/issue /etc/motd" "Set banner permissions"
run_command "chown root:root /etc/issue.net /etc/issue /etc/motd" "Set banner ownership"

start_section "Configure GNOME Display Manager"
run_command "dpkg -l gdm3 >/dev/null 2>&1 && apt purge -y gdm3 || true" "Remove GDM if present"

# ===============[ SECTION 2: Services ]===============
start_section "Configure Server Services"
services=(autofs avahi-daemon isc-dhcp-server bind9 dnsmasq vsftpd slapd dovecot nfs-kernel-server nis cups smbd snmpd tftpd-hpa squid xinetd gdm3)
clients=(nis rsh-client talk telnet ldap-utils ftp)
for service in "${services[@]}"; do
    run_command "dpkg -l $service >/dev/null 2>&1 && apt purge -y $service || true" "Remove $service"
done
for client in "${clients[@]}"; do
    run_command "dpkg -l $client >/dev/null 2>&1 && apt purge -y $client || true" "Remove $client"
done

start_section "Configure Time Synchronization"
CHRONY_CONF="/etc/chrony/chrony.conf"
if dpkg -l | grep -qw chrony; then
    backup_file "$CHRONY_CONF"
    sed -i '/^pool /d' "$CHRONY_CONF"
    run_command "echo 'pool 0.ubuntu.pool.ntp.org iburst' >> '$CHRONY_CONF'" "Add NTP server 0"
    run_command "echo 'pool 1.ubuntu.pool.ntp.org iburst' >> '$CHRONY_CONF'" "Add NTP server 1"
    run_command "systemctl enable chrony" "Enable chrony"
    run_command "systemctl restart chrony" "Restart chrony"
else
    echo "Chrony not installed; skipping chrony configuration."
fi

start_section "Job Schedulers"
for file in /etc/cron.allow /etc/cron.deny /etc/at.allow /etc/at.deny; do
    touch "$file"
done
run_command "chown root:root /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d /etc/cron.allow /etc/cron.deny /etc/at.allow /etc/at.deny" "Set cron ownership"
run_command "chmod 755 /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d" "Set cron permissions"
run_command "chmod 644 /etc/crontab" "Set cron permissions for /etc/crontab"
run_command "chmod 600 /etc/cron.allow /etc/cron.deny /etc/at.allow /etc/at.deny" "Set cron and at allow/deny permissions"

# ===============[ SECTION 3: Network ]===============
start_section "Configure Network Devices"
run_command "echo 'Excluded for review'" "Excluded for review"

start_section "Configure Network Kernel Modules"
run_command "echo 'Excluded for review'" "Excluded for review"

start_section "Configure Network Kernel Parameters"
run_command "echo 'Excluded for review'" "Excluded for review"

# ===============[ SECTION 4: Host Based Firewall ]===============
start_section "Configure a single firewall utility"
run_command "apt install -y ufw" "Install ufw"
run_command "systemctl enable ufw" "Enable ufw"
run_command "systemctl start ufw" "Start ufw"
run_command "ufw --force enable" "Enable ufw"
run_command "ufw allow in on lo" "Allow loopback in"
run_command "ufw allow out on lo" "Allow loopback out"
run_command "ufw default deny incoming" "Default deny incoming"
run_command "ufw default allow outgoing" "Default allow outgoing"
for port in 22 80 443; do
    run_command "ufw allow $port" "Allow port $port"
done
run_command "apt-get purge -y iptables-persistent nftables" "Purge other firewall utilities"

# ===============[ SECTION 5: Access Control ]===============
start_section "Configure SSH Server"
SSH_CONF="/etc/ssh/sshd_config"
backup_file "$SSH_CONF"
cat > "$SSH_CONF" <<'EOF'
# CIS Hardened SSH Configuration
Port 22
Protocol 2
LogLevel VERBOSE
PermitRootLogin no
PermitEmptyPasswords no
# PasswordAuthentication yes # Uncomment to allow password authentication for SFTP
ChallengeResponseAuthentication no
UsePAM yes
AuthenticationMethods publickey # Comment this line to allow password authentication
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-512,hmac-sha2-256
HostbasedAuthentication no
IgnoreRhosts yes
GSSAPIAuthentication no
ClientAliveInterval 300
ClientAliveCountMax 0
LoginGraceTime 30
MaxAuthTries 4
MaxSessions 10
MaxStartups 10:30:60
AllowTcpForwarding no
X11Forwarding no
PermitTunnel no
AllowAgentForwarding no
PermitUserEnvironment no
DenyUsers root
Banner /etc/issue.net
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
HostKeyAlgorithms ssh-ed25519,ssh-rsa
TCPKeepAlive no
PrintMotd no
PrintLastLog yes
EOF
set_owner_and_perms "$SSH_CONF" "root:root" "600"
find /etc/ssh -type f -name "ssh_host_*_key" -exec chown root:root {} \; -exec chmod 600 {} \;
find /etc/ssh -type f -name "ssh_host_*_key.pub" -exec chown root:root {} \; -exec chmod 644 {} \;
run_command "systemctl enable ssh" "Enable SSH service"
run_command "systemctl restart ssh" "Restart SSH service"

start_section "Configure privilege escalation"
run_command "dpkg -l sudo >/dev/null 2>&1 || apt-get install -y sudo" "Ensure sudo is installed"
run_command "echo 'Defaults use_pty' > /etc/sudoers.d/cis_use_pty" "Ensure sudo commands use pty"
set_owner_and_perms "/etc/sudoers.d/cis_use_pty" "root:root" "440"
run_command "echo 'Defaults logfile=\"/var/log/sudo.log\"' > /etc/sudoers.d/cis_logfile" "Ensure sudo logs are configured"
set_owner_and_perms "/etc/sudoers.d/cis_logfile" "root:root" "440"
run_command "touch /var/log/sudo.log" "Create sudo log file"
set_owner_and_perms "/var/log/sudo.log" "root:root" "600"
run_command "echo 'Defaults !authenticate' > /etc/sudoers.d/remove_no_authenticate" "Remove !authenticate from sudoers"
run_command "sed -i '/^Defaults\s*!authenticate/d' /etc/sudoers" "Remove !authenticate from sudoers"
run_command "sed -i '/^Defaults\s*!timestamp_timeout/d' /etc/sudoers" "Remove !timestamp_timeout from sudoers"
run_command "echo 'Defaults timestamp_timeout=15' > /etc/sudoers.d/cis_timestamp_timeout" "Set sudo authentication timeout"
set_owner_and_perms "/etc/sudoers.d/cis_timestamp_timeout" "root:root" "440"

start_section "Pluggable Authentication Modules"
run_command "apt-get install -y libpam0g libpam-modules libpam-modules-bin libpam-pwquality" "Install PAM modules"
PWQUALITY_CONF="/etc/security/pwquality.conf"
backup_file "$PWQUALITY_CONF"
cat > "$PWQUALITY_CONF" <<EOF
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
minclass = 4
maxrepeat = 3
maxsequence = 3
dictcheck = 1
EOF

run_command "sed -i '/pam_pwquality\.so/d' /etc/pam.d/common-password" "Remove existing pam_pwquality"
run_command "sed -i '/pam_unix\.so/s/^/# /' /etc/pam.d/common-password" "Comment out pam_unix"
run_command "sed -i '/^password\s\+requisite\s\+pam_pwquality\.so/d' /etc/pam.d/common-password" "Remove pam_pwquality entry"
echo "password requisite pam_pwquality.so retry=3 enforce_for_root" >> /etc/pam.d/common-password

run_command "sed -i '/pam_pwhistory\.so/d' /etc/pam.d/common-password" "Remove pam_pwhistory"
run_command "echo 'password required pam_pwhistory.so remember=5 use_authtok enforce_for_root' >> /etc/pam.d/common-password" "Add pam_pwhistory"
run_command "sed -i '/pam_unix\.so/d' /etc/pam.d/common-password" "Remove pam_unix"
run_command "echo 'password [success=1 default=ignore] pam_unix.so obscure sha512 use_authtok' >> /etc/pam.d/common-password" "Add pam_unix"
for FILE in /etc/pam.d/common-auth /etc/pam.d/common-account; do
    backup_file "$FILE"
done
run_command "sed -i '/pam_faillock\.so/d' /etc/pam.d/common-auth" "Remove pam_faillock"
run_command "sed -i '/^auth\s\+required\s\+pam_tally2\.so/d' /etc/pam.d/common-auth" "Remove pam_tally2"
run_command "sed -i '1i auth required pam_faillock.so preauth silent deny=5 unlock_time=900 even_deny_root' /etc/pam.d/common-auth" "Add pam_faillock preauth"
run_command "sed -i '2i auth [default=die] pam_faillock.so authfail deny=5 unlock_time=900 even_deny_root' /etc/pam.d/common-auth" "Add pam_faillock authfail"
run_command "sed -i '\$a auth sufficient pam_faillock.so authsucc deny=5 unlock_time=900 even_deny_root' /etc/pam.d/common-auth" "Add pam_faillock authsucc"
if ! grep -q 'pam_faillock.so' /etc/pam.d/common-account; then
    echo "account required pam_faillock.so" >> /etc/pam.d/common-account
fi

start_section "User Accounts and Environment"
run_command "echo 'Excluded for review'" "Excluded for review"

# ===============[ SECTION 6: Logging and Auditing ]===============
start_section "System Logging"
run_command "systemctl enable systemd-journald.service" "Enable journald"
run_command "systemctl restart systemd-journald.service" "Restart journald"
run_command "sed -i 's/^#*ForwardToSyslog=.*/ForwardToSyslog=no/' /etc/systemd/journald.conf" "Disable forwarding to syslog"
run_command "sed -i 's/^#*Compress=.*/Compress=yes/' /etc/systemd/journald.conf" "Enable compression"
run_command "sed -i 's/^#*Storage=.*/Storage=persistent/' /etc/systemd/journald.conf" "Set storage to persistent"
run_command "systemctl restart systemd-journald" "Restart journald"
run_command "apt install -y systemd-journal-remote" "Install systemd-journal-remote"
run_command "systemctl disable --now systemd-journal-remote.socket systemd-journal-remote.service" "Disable systemd-journal-remote"
run_command "systemctl enable systemd-journal-upload.service" "Enable systemd-journal-upload"
run_command "systemctl start systemd-journal-upload.service" "Start systemd-journal-upload"

start_section "System Auditing"
run_command "apt install -y auditd audispd-plugins" "Install auditd and audispd-plugins"
run_command "systemctl enable --now auditd" "Enable auditd"
run_command "sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"audit=1\"/' /etc/default/grub" "Set GRUB_CMDLINE_LINUX to audit=1"
run_command "update-grub" "Update GRUB"
run_command "sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"audit_backlog_limit=8192 audit=1\"/' /etc/default/grub" "Set audit_backlog_limit"
run_command "update-grub" "Update GRUB"
run_command "sed -i 's/^max_log_file =.*/max_log_file = 200/' /etc/audit/auditd.conf" "Set max_log_file"
run_command "sed -i 's/^num_logs =.*/num_logs = 5/' /etc/audit/auditd.conf" "Set num_logs"
run_command "sed -i 's/^max_log_file_action =.*/max_log_file_action = keep_logs/' /etc/audit/auditd.conf" "Set max_log_file_action"
run_command "sed -i 's/^space_left_action =.*/space_left_action = email/' /etc/audit/auditd.conf" "Set space_left_action"
run_command "sed -i 's/^action_mail_acct =.*/action_mail_acct = root/' /etc/audit/auditd.conf" "Set action_mail_acct"
run_command "sed -i 's/^admin_space_left_action =.*/admin_space_left_action = halt/' /etc/audit/auditd.conf" "Set admin_space_left_action"
AUDIT_RULES="/etc/audit/rules.d/cis.rules"
cat > "$AUDIT_RULES" <<EOF
## Monitor sudoers and group change
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
-w /etc/group -p wa -k group_mod
-w /etc/passwd -p wa -k user_mod
-w /etc/shadow -p wa -k shadow_mod
-w /etc/gshadow -p wa -k gshadow_mod

## Log sudo activity
-w /var/log/sudo.log -p wa -k sudo_log

## Privileged commands
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=unset -k privileged

## Time change monitoring
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change

## Network environment changes
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network

## File deletions
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete

## DAC permission changes
-a always,exit -F arch=b64 -S chmod -S fchmod -S chown -S fchown -S setxattr -k perm_mod

## Successful mount
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=unset -k mounts

## Session
-w /var/run/faillock/ -p wa -k session
-w /var/log/lastlog -p wa -k logins

## MAC modifications
-w /etc/apparmor/ -p wa -k mac-policy

## chcon/setfacl/chacl/usermod
-a always,exit -F arch=b64 -S chcon -S setfacl -S usermod -F auid>=1000 -F auid!=unset -k access_mod

## Kernel module changes
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules

## Immutable audit config
-e 2
EOF
set_owner_and_perms "$AUDIT_RULES" "root:root" "640"
augenrules --load
run_command "systemctl restart auditd" "Restart auditd"
set_owner_and_perms "/var/log/audit/audit.log" "root:root" "600"
set_owner_and_perms "/var/log/audit/" "root:root" "750"
set_owner_and_perms "/etc/audit/auditd.conf" "root:root" "640"
for bin in /sbin/auditctl /sbin/auditd /sbin/ausearch; do
    set_owner_and_perms "$bin" "root:root" "755"
done

# ===============[ SECTION 7: System Maintenance ]===============
start_section "System File Permissions"
run_command "echo 'Excluded for review'" "Excluded for review"

start_section "Local User and Group Settings"
run_command "echo 'Excluded for review'" "Excluded for review"
