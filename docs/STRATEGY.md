# JR Pi Toolkit Strategy
Golden SD + NVMe “Swiss Army disk” provisioning

## The core idea
One repo, two boot contexts:

- **Golden SD (installer mode)**:
  - prep the SD environment
  - set NVMe first-boot networking
  - flash NVMe (destructive, gated)
  - seed identity (user, SSH keys, hostname, toolkit install)

- **NVMe (runtime mode)**:
  - provisioning (packages, services, config)
  - Pi-Apps + workloads (explicit opt-in)
  - health checks + status dashboard
  - backup/imaging/sanitize utilities

The menu must make it hard to do the wrong thing in the wrong mode.

## Non-negotiables
1) **TOOLKIT_ROOT everywhere**
   - Menu derives TOOLKIT_ROOT from the real script path (`readlink -f ${BASH_SOURCE[0]}`) once and never overwrites it.
   - All scripts reference sibling scripts via `$TOOLKIT_ROOT/...`
   - Avoid hardcoded `/jr-...` or mixed paths.

2) **Safe reruns (idempotent)**
   - Re-running an option should not break a working system.
   - Use markers where needed (example: `/var/local/pi-provision.done`).
   - When unsure, default to “no change” unless user explicitly confirms.

3) **Safety gates for destructive actions**
   - Typed phrase confirmation for disk writes and identity reseeds.
   - Prefer explicit target discovery (list disks, require selection).
   - Refuse to proceed if target is ambiguous.

4) **Logging discipline**
   - Every menu action runs through a wrapper:
     - creates a timestamped log file
     - writes a BEGIN/END header with mode/root/toolkit/command
     - updates `last-run.log` symlink
   - Do not use `script -c` for logging menu actions (TTY/quoting issues). Append output directly.
   - Keep logs in one stable place:
     - primary: `/var/log/jr-pi-toolkit/`
     - fallback (if needed): `/var/local/state/jr-pi-toolkit/logs/`

5) **Doctor/Preflight is the bouncer**
   - Doctor validates:
     - required scripts exist + executable
     - bash syntax parses
     - config file present
     - launcher sanity
     - boot-mode logic sanity
     - permissions for logging
     - keys directory hygiene (public keys only committed)
   - Doctor should point at exact fixes, not vibes.

## Configuration strategy
- Keep defaults in repo: `jr-toolkit.conf`
- Allow override (later): `/etc/jr-toolkit.conf`
- Load order: repo defaults -> system override -> environment vars

## UX strategy
- Always show:
  - detected root device
  - toolkit root directory
  - mode indicator (SD vs NVMe)
  - right-side tags: [SD only], [NVMe only], [ALL], [help], [status]
- Help option should describe the intended “happy path” in 8 lines max.

## Git strategy (lightweight)
- Work happens on feature branches.
- Each chunk gets a commit with a clear message.
- Merge to main via PR when:
  - menu works
  - doctor passes
  - no obvious foot-guns

## Future work (guiding priorities)
1) Central config + clean variable loading
2) Doctor becomes authoritative (more checks, more actionable output)
3) Case installers: opt-in, idempotent, reversible where possible
4) Reduce “mystery state”: visible mode + visible last action + visible log
