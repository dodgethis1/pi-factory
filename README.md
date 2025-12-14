# JR Pi Toolkit

Golden SD (installer) + NVMe (runtime) provisioning toolkit.

Run:
  cd /opt/jr-pi-toolkit
  bash ./pi-menu.sh

Rules:
- Destructive actions require typed confirmation.
- Use TOOLKIT_ROOT paths (no /jr-*.sh hardcoding).
- Re-runs should be safe (idempotent).
