# Session Summary: 2025-09-20 (2)

## Key Developments:
- Investigated the interaction between two concurrent Gemini CLI processes.
- Discovered that the built-in `/home/igor/gemini_projects/.gemini/gemini_actions.log` does not automatically log every single command as initially assumed. My assumption was proven wrong by a practical test.
- Established a new, explicit, and reliable manual logging procedure to ensure all actions are tracked.

## Changes Implemented:
- Created a new manual log file: `/home/igor/gemini_projects/gemini_manual_log.txt`.
- Added a new `Operational Guideline` to my core configuration file (`/home/igor/gemini_projects/.gemini/GEMINI.md`) to enforce the new manual logging rule in all future sessions.
- Successfully tested the new procedure by logging the configuration change itself.
