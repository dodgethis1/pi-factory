# --- JR Toolkit first-run marker ---
sudo mkdir -p /var/lib/jr-toolkit
sudo touch /var/lib/jr-toolkit/first-run.done

# --- Regenerate SSH host keys (prevents cloned-key weirdness) ---
# This will cause a one-time new fingerprint after first-run (normal).
sudo rm -f /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
sudo systemctl restart ssh
