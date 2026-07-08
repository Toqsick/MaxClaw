# MCP GitHub Server Quirks — Batch File Push Session (2026-07-07)

Session: push the same `CONTRIBUTING.md` to 4 repos (`hermes-v7`, `MaxClaw`, `hermes-v7-sse-dashboard`, `multi-agent-workflows`) using the GitHub Contents API.

This complements the existing `references/batch-contributing-md-push-2026-07-07.md` (which documents the 409 stale-SHA pitfall). **Today's session surfaced a different problem class: MCP GitHub tool responses cannot be trusted for existence checks.**

## What happened

1. **Discovery phase used `mcp__github__get_file_contents` and `list_branches`** — both returned success with a uniform sentinel SHA `777035533703e3b24b90916e17598aeb2f8fb17a` for *every* file lookup, including files that didn't exist. Cross-check via `curl https://api.github.com/repos/OWNER/REPO/contents/CONTRIBUTING.md` revealed:
   - `MaxClaw`: 200 OK, file exists with the sentinel SHA
   - `hermes-v7`, `sse-dashboard`, `multi-agent-workflows`, `greyscripts`: 404 Not Found — file genuinely does not exist
2. **First write attempt via `mcp__github__create_or_update_file`** (no SHA) on `hermes-v7` returned the error:
   ```
   File already exists at CONTRIBUTING.md. You must provide the current file's SHA when updating.
   Use git rev-parse main:CONTRIBUTING.md to get the blob SHA, then retry with the sha parameter.
   ```
   This was **wrong** — curl 404 had just confirmed the file didn't exist. Same error fired for `sse-dashboard` and `multi-agent-workflows`.
3. **Tool-loop warning** appeared after 3 failures of the same tool. Retried with an explicit SHA — got:
   ```
   MCP server 'github' is unreachable after 3 consecutive failures. Auto-retry available in ~32s.
   Do NOT retry this tool yet — use alternative approaches or ask the user to check the MCP server.
   ```
4. **Verified writes actually succeeded** by listing the repo root via curl — `CONTRIBUTING.md` was present in `hermes-v7` despite the MCP error. All 4 repos ended up with the same blob SHA `777035533703...`, identical content (553 B).
5. **Content needed reconciliation** — the 4 repos had a slightly enriched version ("Open a PR against `main`", "Use issue templates if available") not matching the task's exact template (530 B, "Open a PR against the default branch"). Used direct `curl -X PUT` with `gh auth token` to update all 4 in parallel with the correct SHA, getting HTTP 200 + new blob SHA `97a9b0c9b753ece67473ed26fe8cb7c7ea35ec4e`.
6. **Cleaned up probe file** `__probe_test_<pid>.md` accidentally created in `hermes-v7` during MCP bypass. `curl -X DELETE` with the file's blob SHA + `gh auth token` returned HTTP 200.

## Patterns that emerged

### 1. MCP existence checks are unreliable — always curl-confirm

```bash
HTTP=$(curl -s -o /tmp/r.json -w "%{http_code}" \
  "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH?ref=$BRANCH")
if [ "$HTTP" = "200" ]; then
  SHA=$(python3 -c "import json; print(json.load(open('/tmp/r.json'))['sha'])")
  SIZE=$(python3 -c "import json; print(json.load(open('/tmp/r.json'))['size'])")
elif [ "$HTTP" = "404" ]; then
  # File genuinely does not exist — Create path
else
  # Other HTTP code — investigate
fi
```

Sentinel SHA to recognize as "MCP didn't actually fetch" indicator: `777035533703e3b24b90916e17598aeb2f8fb17a` (observed on multiple repos in this session).

### 2. Direct curl + `gh auth token` as MCP bypass

When MCP server enters cooldown (after 3 failures or server unreachable), fall back to direct API calls:

```bash
TOKEN="$(gh auth token)"
B64=$(base64 -w0 /path/to/local/file)
SHA=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH?ref=$BRANCH" \
  -u "Toqsick:$TOKEN" | python3 -c "import json,sys; print(json.load(sys.stdin)['sha'])")

# PUT body via python for safe JSON escaping
python3 -c "
import json
print(json.dumps({
  'message': 'docs: align CONTRIBUTING.md with template',
  'content': '''$B64''',
  'sha': '$SHA',
  'branch': '$BRANCH',
}))" > /tmp/putbody.json

HTTP=$(curl -s -X PUT -o /tmp/putresp.json -w "%{http_code}" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  -u "Toqsick:$TOKEN" \
  --data-binary @/tmp/putbody.json \
  "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH")
# HTTP 200 → success, parse /tmp/putresp.json for new commit SHA
```

**Why `python3 -c` for JSON body construction, not heredoc:** base64 content with embedded newlines and shell variable interpolation. Heredoc escaping fails on edge cases; python with triple-quoted string + `'$VAR'` substitution is bulletproof.

### 3. Post-batch MD5 / SHA cross-check

Every PUT returned `200 OK` + `commit.sha`, but that doesn't prove content is correct. After a multi-repo batch:

```bash
SOURCE=$(cat /path/to/local/file)
for entry in "hermes-v7:main" "MaxClaw:main" "hermes-v7-sse-dashboard:master" "multi-agent-workflows:main"; do
  repo="${entry%%:*}"; branch="${entry##*:}"
  REMOTE=$(curl -s "https://api.github.com/repos/$OWNER/$repo/contents/$PATH?ref=$branch" \
    -u "Toqsick:$TOKEN" | python3 -c "import json,sys,base64; print(base64.b64decode(json.load(sys.stdin)['content']).decode())")
  [ "$SOURCE" = "$REMOTE" ] && echo "MATCH $repo" || echo "DIFFER $repo"
done
```

The session found all 4 repos had identical content (same blob SHA) — but only after content-reconciliation pushes. The initial "MCP succeeded silently" batch had a 553 B version, the second curl-driven batch had the correct 530 B template.

## Final state

| Repo | Branch | Blob SHA | Size | Commit |
|---|---|---|---|---|
| Toqsick/hermes-v7 | `main` | `97a9b0c9b753ece67473ed26fe8cb7c7ea35ec4e` | 530 B | `fa48b64d4259` |
| Toqsick/MaxClaw | `main` | `97a9b0c9b753ece67473ed26fe8cb7c7ea35ec4e` | 530 B | `d76513e902d8` |
| Toqsick/hermes-v7-sse-dashboard | `master` | `97a9b0c9b753ece67473ed26fe8cb7c7ea35ec4e` | 530 B | `8cfa000885bb` |
| Toqsick/multi-agent-workflows | `main` | `97a9b0c9b753ece67473ed26fe8cb7c7ea35ec4e` | 530 B | `f9471c85262c` |

All 4 repos verified by re-fetching via `GET /contents/CONTRIBUTING.md` and decoding — byte-identical to local template.

## Takeaway for future sessions

1. **Never trust MCP tool responses for existence or content shape without curl verification.** The MCP tool's "success" indicator is unreliable; the SHA field may be a sentinel.
2. **Have a curl fallback pre-built.** Keep a `gh api -X PUT` / `curl -X PUT` recipe in scope before starting a batch push, in case MCP enters cooldown mid-task.
3. **Verify the actual content after every batch push**, not just the HTTP status. The session found two layers of writes (one MCP-driven with wrong content, one curl-driven with correct content) — only the byte-equality check confirmed which was authoritative.
4. **Cleanup probe files immediately.** When bypassing MCP by writing to a test filename to confirm the path works, always `DELETE` after, using the file's blob SHA from the contents lookup.