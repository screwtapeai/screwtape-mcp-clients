# Screwtape.ai for MCP clients (Claude Desktop, Claude Code, Cursor, Windsurf)

[![Listed on MCP Collection](https://mcpcollection.com/badge/screwtape-ai.svg)](https://mcpcollection.com/server/screwtape-ai)

A judge for your agents that sits outside your agent stack. Screwtape isn't tied to any agent framework or AI model provider, so its verdicts never grade their own work. Every verdict comes with a signed receipt you can verify yourself, which gives you a record you can trust when it matters.

False-consensus check and pass/fail/retry verdicts inside your MCP client. Screwtape.ai runs a remote MCP server over **Streamable HTTP** at `https://screwtape.ai/mcp` (protocol 2025-03-26 and 2025-06-18). It's listed in the official MCP Registry as `ai.screwtape/screwtape`. Its tools:

| Tool | Use it to | Auth |
|---|---|---|
| `judge` | Get pass, fail or retry, a score, reasons and (when signing is on) a signed receipt for one output (`task`, `agent_output`, optional `evidence`, `criteria`, `retain`) | Bearer key |
| `check_duplicate_invoice` | Check an invoice for duplicates before the agent pays: the judge inputs plus a `duplicate` object; returns `duplicate.status` and `next_step` | Bearer key |
| `consensus` | Score 2 to 16 answers (`task`, `answers[{agent_id?, output}]`) and get `false_consensus_risk` | Bearer key |
| `get_api_key` | Create a free key (`pow_nonce` required; `email` and `name` optional) | None |
| `publish_receipt` | Publish one signed receipt you own as a public page and badge | Bearer key (the receipt's owner) |

## What it does

These are ready-to-copy configs that connect each client to `https://screwtape.ai/mcp` with your key read from the environment. Then ask the assistant to call `judge` on its draft with your evidence: answer only on `pass`, revise on `retry`, and stop on `fail`.

## Files

- `claude_desktop_config.json`: Claude Desktop through the `mcp-remote` bridge (pinned `mcp-remote@0.15.2`)
- `claude-code.mcp.json`: a project `.mcp.json` for Claude Code
- `cursor.mcp.json`: `~/.cursor/mcp.json` or `.cursor/mcp.json`
- `windsurf.mcp_config.json`: Windsurf (Cascade) `mcp_config.json`
- `smoke_test.sh`: `tools/list` (no key) and one `judge` call (with a key)
- `get_free_key.py`: proof-of-work signup for a free key (Python stdlib)
- `.env.example`, `.gitignore`, `LICENSE` (MIT)

## Setup

### Claude Desktop

- **Recommended:** add a custom connector (Customize → Connectors → Add → Custom → Web). Enter `https://screwtape.ai/mcp` and add the request header `Authorization: Bearer <key>` (https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).
- **Config-file route:** `claude_desktop_config.json` only starts local processes, so this file uses `mcp-remote` as a bridge. Note `"Authorization:${AUTH_HEADER}"` with no space after the colon: mcp-remote's README documents that workaround for clients that don't escape spaces in `args`. Replace the placeholder in `env.AUTH_HEADER` with `Bearer <key>` in your local copy only. Claude Desktop doesn't read your shell environment.

### Claude Code

Copy `claude-code.mcp.json` to `.mcp.json`. Claude Code needs `"type": "http"` and expands `${SCREWTAPE_API_KEY}` from the environment (https://code.claude.com/docs/en/mcp).

### Cursor

Copy `cursor.mcp.json` into `~/.cursor/mcp.json` or `.cursor/mcp.json`. Cursor resolves `${env:SCREWTAPE_API_KEY}` in `headers` (https://cursor.com/docs/context/mcp).

### Windsurf

Paste `windsurf.mcp_config.json` into Cascade's `mcp_config.json`. Remote servers use `serverUrl` and `headers`, with `${env:VAR}` interpolation. Per Windsurf's docs (https://docs.windsurf.com/windsurf/cascade/mcp, read 2026-10-21), the file is at `~/.config/devin/mcp_config.json` on macOS and Linux and `%APPDATA%\devin\mcp_config.json` on Windows, for the legacy Cascade agent.

### Check it

```bash
export SCREWTAPE_API_KEY=...   # or use .env.example
sh smoke_test.sh
```

The judge call uses one of your 10 daily calls. Expect a non-`pass` verdict, because the output says 5 and the evidence says 4.

## Signed verdict receipts

When receipt signing is on, every `/v1/judge` and `/v1/consensus` response also carries a `receipt` object. The fields are `receipt_id`, `issued_at`, `endpoint`, `request_sha256` (SHA-256 of the normalized request), `verdict`, `score`, `payment`, `alg` (`Ed25519`), `kid` and `signature`. For consensus, `verdict` is `false_consensus_risk` and `score` is `agreement_score`. `payment` shows the key prefix, never the key.

- Public keys: https://screwtape.ai/.well-known/screwtape-receipt-keys.json (JWKS-style Ed25519)
- Verify: `POST https://screwtape.ai/v1/receipts/verify` with the raw `receipt` object as the request body, exactly as returned (not wrapped in `{"receipt": ...}`). The response is `{"valid": true}` or `{"valid": false}`. No key is needed and the receipt isn't stored.

The MCP tools return the same JSON as the REST endpoints, including `receipt`. Paste it into the verify call:

```bash
# receipt.json holds the raw receipt object, not {"receipt": ...}
curl -s https://screwtape.ai/v1/receipts/verify -H "Content-Type: application/json" -d @receipt.json
```

Store the receipt next to the output it approved, so a reviewer can later check which request was judged, the verdict it got, and when.

## Get a free key (10 calls per UTC day)

- **In a browser:** https://screwtape.ai/signup/ (email and name are optional, no card). To try judge and consensus with no key first, use https://screwtape.ai/try/ (3 calls per token, about 30 minutes).
- **From code or an agent:** `POST https://screwtape.ai/v1/signup` with a proof of work. The SHA-256 of `screwtape-signup-v1:<UTC YYYY-MM-DD>:<nonce>` must start with 12 zero bits, and the nonce must match `^[A-Za-z0-9_-]{8,64}$`. `python3 get_free_key.py --name my-agent` does this (`--dry-run` only finds the nonce). The `get_api_key` tool does the same inside a client, but a chat model can't reliably compute SHA-256 itself, so run the script.
- The key is shown **once**. Screwtape stores only its SHA-256 hash. Limits are 5 keys per IP per hour and 5 per UTC day.
- Copy `.env.example` to `.env` (git-ignored) or export `SCREWTAPE_API_KEY`. The code reads the key from the environment and never embeds it.

## Plans

- **Free:** 10 calls per UTC day with a free key.
- **Sandbox Evaluation Pack:** $100 for 2,000 checks. See https://screwtape.ai/pricing/.
- **Enterprise pilot:** email support@screwtape.ai.

A `tools/call` for `judge`, `check_duplicate_invoice` or `consensus` without an `Authorization` header returns `isError: true`. Set the key as shown above.

## Links

- Screwtape.ai: https://screwtape.ai/
- API reference: https://screwtape.ai/docs/ · OpenAPI: https://screwtape.ai/openapi.json · For agents: https://screwtape.ai/llms.txt
- MCP server: https://screwtape.ai/mcp (MCP Registry name `ai.screwtape/screwtape`)
- Pricing: https://screwtape.ai/pricing/ · Free key: https://screwtape.ai/signup/
- Source for this example: https://github.com/screwtapeai/screwtape-mcp-clients
- Issues: https://github.com/screwtapeai/screwtape-mcp-clients/issues

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Screwtape.ai.

---
Screwtape.ai is an agent validation API, not the arXiv paper that is also named Screwtape. This example was checked against the live API on 2026-10-21.
