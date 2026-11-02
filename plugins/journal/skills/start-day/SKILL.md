---
name: start-day
description: Create today's empty page in my Notion work journal with the right properties, ready for notes. Use at the start of a work day. Not for logging session work (use /journal).
disable-model-invocation: true
allowed-tools: mcp__notion__notion-query-data-sources, mcp__notion__notion-fetch, mcp__notion__notion-create-pages, mcp__notion__notion-update-page, mcp__notion__notion-create-view, Read
---

## Today

!`"${CLAUDE_SKILL_DIR}/../journal/today.sh"`

Do not infer any of these values from memory. If the block above says NOT CONFIGURED, show its instructions to the user and stop.

## Where the journal lives

- **MCP server**: the one named in the Today block. Tool names below are its short names; never use a different Notion server.
- **Data source**: the "Data source id" above. Its URL form is `collection://<id>`.

## Correct daily page properties

- `Name` = ISO date
- `Tags` = `'["Work","Daily"]'`
- `date:Start Date:start` = ISO date
- `date:Start Date:is_datetime` = `0`

## Steps

**1. Look up both pages.** Make one `notion-query-data-sources` call in `rows` mode, which matches titles exactly. Never use `notion-search` for this; it ranks by relevance and can miss a page that exists.
```json
{"data": {"mode": "rows", "data_source_url": "collection://<data source id>", "limit": 5, "filter": {"type": "group", "operator": "or", "filters": [
  {"type": "property", "property": "Name", "propertyType": "title", "operator": "string_is", "value": {"type": "exact", "value": "<month label>"}},
  {"type": "property", "property": "Name", "propertyType": "title", "operator": "string_is", "value": {"type": "exact", "value": "<ISO date>"}}
]}}}
```
The row named the ISO date is today's page. The row named the month label is the monthly index.

<condition>
  <when>The query fails</when>
  <on-yes>Stop and report the error. Create nothing, because an unknown result can duplicate a page.</on-yes>
</condition>

- No monthly row: read `${CLAUDE_SKILL_DIR}/../journal/monthly-index.md` and follow "Create".

<condition>
  <when>Step 1 found today's page</when>

  <on-yes>
    Fetch it with `notion-fetch`. If `Tags` or `Start Date` differ from the correct properties above, fix them with `notion-update-page` `command: "update_properties"`, setting all four. If the page has no icon, set `icon` = the callout icon, in the same call when properties also need fixing. Never touch the page body. Report "already started" with the page URL and any property corrected.
  </on-yes>

  <on-no>
    Create with `notion-create-pages`:
    - `parent`: `{"type": "data_source_id", "data_source_id": "<the data source id>"}`
    - `properties`: the correct daily page properties above
    - `icon`: the callout icon
    - no `content`
    - `allow_async`: `false`

    Fetch the new page and confirm `Name`, `Tags`, `Start Date`, and the page icon match. Correct any that do not, then report the page URL.
  </on-no>
</condition>

<hard-rules>
  <rule>Never write content into the daily page. This skill only sets properties.</rule>
  <rule>Never create a second page for a date that already has one.</rule>
</hard-rules>
