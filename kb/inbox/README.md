# Inbox

The inbox file lives outside the repo:
`C:\Users\mikew\OneDrive\Desktop\Achaea Knowledge Base.txt`

`snapshot.txt` in this folder is a copy of that file as it was at the last ingest.
`python tools/kb_inbox.py status` diffs the live file against it to show what is new, and
`python tools/kb_inbox.py mark` updates it once the new material is filed. Do not edit
`snapshot.txt` by hand.

Pass `--src <path>` to either command to ingest a different file.
