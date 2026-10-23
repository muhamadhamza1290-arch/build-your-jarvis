#!/bin/bash
# File guard (PreToolUse on Bash and Read). Local only, no network.
# Blocks, BEFORE they run:
#   1. Recursive, wildcard or bulk deletes, and git commands that destroy work.
#   2. Reading or printing secret files (.env, private keys) into the chat.
#   3. Sending secret files over the network.
# A block only stops the command and tells Claude the safe alternative.
# It is a safety net, not a security guarantee. Keep Claude Code's permission prompts on.

INPUT="$(cat)"
json_get() {  # json_get <dotted.key>
  printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
    v=json.load(sys.stdin)
    for k in sys.argv[1].split("."): v=v.get(k,"") if isinstance(v,dict) else ""
except Exception: v=""
print(v)' "$1" 2>/dev/null
}
deny() {
  python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]}}))' "$1"
  exit 0
}

SECRET='(\.env([^a-zA-Z.]|$)|\.env\.[a-z]+|id_rsa|id_ed25519|\.pem([^a-zA-Z]|$)|\.p12|\.key([^a-zA-Z]|$)|\.ssh/|credentials\.json)'
is_example() { printf '%s' "$1" | grep -Eq '\.env\.(example|sample|template)'; }

tool="$(json_get tool_name)"

if [ "$tool" = "Read" ]; then
  f="$(json_get tool_input.file_path)"
  if printf '%s' "$f" | grep -Eq "$SECRET" && ! is_example "$f"; then
    deny "Rule 6: secret files (.env, keys) are never read into the chat. Use them through a script (for example: source .env) without printing values. The owner can open the file themselves."
  fi
  exit 0
fi

[ "$tool" = "Bash" ] || exit 0
cmd="$(json_get tool_input.command)"
seg='[^;&|]*'   # stay inside one command segment

# 2 + 3: secrets (only when the secret file is an argument of the same command)
if ! is_example "$cmd"; then
  if printf '%s' "$cmd" | grep -Eq "(^|[^a-z])(curl|wget|nc|scp|sftp|rsync|ftp|ssh)[[:space:]]$seg$SECRET"; then
    deny "Rule 6: secret files are never sent over the network. Ask the owner; they do it themselves if it is truly needed."
  fi
  if printf '%s' "$cmd" | grep -Eq "(^|[^a-z])(cat|less|more|head|tail|strings|xxd|base64|od|grep|awk|sed|cp|pbcopy|xclip)[[:space:]]$seg$SECRET"; then
    deny "Rule 6: secret file contents are never printed or copied. Use them through a script without showing values."
  fi
fi

# 1: destructive deletes
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rR]|--recursive)' \
   || printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]][^;&|]*\*' \
   || printf '%s' "$cmd" | grep -Eq 'find[[:space:]].*-delete' \
   || printf '%s' "$cmd" | grep -Eq 'xargs[[:space:]]+(-[a-zA-Z0-9]+[[:space:]]+)*rm' \
   || printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(clean[[:space:]]+-[a-zA-Z]*f|reset[[:space:]]+--hard|checkout[[:space:]]+--[[:space:]]+\.|push[[:space:]].*(--force|-f([[:space:]]|$)))'; then
  deny "Rule 4: no bulk, recursive or history-destroying deletes. Move the files into backups/<YYYY-MM-DD>/ instead and list what moved. The owner deletes for real."
fi
exit 0
