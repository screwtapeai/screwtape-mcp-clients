#!/usr/bin/env sh
# tools/list needs no key. tools/call judge uses your key (counts against the 100/day).
set -e
H='-H Content-Type:application/json -H Accept:application/json,text/event-stream'
curl -s https://screwtape.ai/mcp $H -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'; echo
[ -n "$SCREWTAPE_API_KEY" ] && curl -s https://screwtape.ai/mcp $H -H "Authorization: Bearer $SCREWTAPE_API_KEY" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"judge","arguments":{"task":"State the crew size.","agent_output":"The crew size was 5.","evidence":["The crew size was 4."]}}}'; echo
