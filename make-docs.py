from pathlib import Path

def w(name, content):
    Path(name).write_text(content.strip() + "\n", encoding="utf-8")

w("README.md", """
# JR Pi Toolkit

Golden SD (installer) + NVMe (runtime) provisioning toolkit.

Run:
  cd /opt/jr-pi-toolkit
  bash ./pi-menu.sh

Rules:
- Destructive actions require typed confirmation.
- Use TOOLKIT_ROOT paths (no /jr-*.sh hardcoding).
- Re-runs should be safe (idempotent).
""")

w("CONTEXT.md", """
# Context

Boot mode from root device:
- SD when / is on /dev/mmcblk*
- NVMe otherwise

SD = installer actions, NVMe = runtime actions.
""")

w("USAGE.md", """
# Usage

Golden SD -> NVMe:
1) Run Options 1,2,3 on SD
2) Power off, remove SD
3) Boot NVMe, run Option 4 when ready
""")

w("ROADMAP.md", """
# Roadmap
- Doctor/preflight: files, perms, bash -n, TOOLKIT_ROOT sanity, log sanity
- Central config: jr-toolkit.conf
- Logging discipline + last-run helper
- Case installers: opt-in, idempotent
""")

w("CHANGELOG.md", """
# Changelog
## Unreleased
- Initial docs
""")

print("Docs written.")
