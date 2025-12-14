# Safety

## Destructive actions (pay attention)
- Flash NVMe (Option 3): wipes/rewrites the target NVMe. Requires typed confirmation phrase.
- Any sanitize/imaging actions: read the prompt twice. Logs exist for a reason.

## Safety rules (toolkit-level)
- Mode gates matter:
  - SD mode = installer actions
  - NVMe mode = runtime actions
- No hardcoded /jr-*.sh paths. Use TOOLKIT_ROOT paths only.
- Reruns should be safe (idempotent). If not safe, add a gate.

## If you are unsure
1) Run Doctor/Preflight.
2) Check the last run log:
   - Option L (menu)
   - /var/log/jr-pi-toolkit/last-run.log

## Logs
- Primary: /var/log/jr-pi-toolkit/
- last-run.log points at the most recent action.
