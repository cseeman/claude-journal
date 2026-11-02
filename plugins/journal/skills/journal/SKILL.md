---
name: journal
description: Record this session's work as an entry in my Notion work journal. Use when wrapping up a Claude Code session or logging work. Not for other Notion edits.
argument-hint: "[entry text (optional)]"
disable-model-invocation: true
allowed-tools: mcp__notion__notion-query-data-sources, mcp__notion__notion-fetch, mcp__notion__notion-create-pages, mcp__notion__notion-update-page, mcp__notion__notion-create-view, Read
---

## Today

!`"${CLAUDE_SKILL_DIR}/today.sh"`

Do not infer any of these values from memory. If the block above says NOT CONFIGURED, show its instructions to the user and stop.

## Where the journal lives

- **MCP server**: the one named in the Today block. Tool names below are its short names; never use a different Notion server.
- **Data source**: the "Data source id" above. Its URL form is `collection://<id>`. "The data source" below means this.

## Entry shape

One callout per topic. A session that touched two unrelated pieces of work writes two callouts, separated by `<empty-block/>`.

```
<callout icon="<callout icon>" color="<callout color>">
	**<headline: the outcome, past tense, under 12 words>**
	[PROJ-1234](url) · [PR 5678](url) · `branch-name`
	- <fact, one sentence, starts with a verb>
	- <fact>
	- Next: <follow-up> / Open: <question, and who owes the answer>
</callout>
```

Use the callout icon and color computed above.

Rules:
- Headline says what is true now, not what was attempted.
- Metadata line is mandatory and lists every ticket, PR, ADR, and branch touched. Link text is the identifier, never the URL. Name the person when a reply is pending. If the session touched none of these, list the files or systems touched instead.
- At most four bullets, each one sentence and a fact. No narrated reasoning ("rather than", "since", "worth noting"). A reason that matters is its own bullet.
- Skip a `Next:` or `Open:` bullet already on today's page unless its status changed.
- About 80 words per callout. More than that is two topics.
- No em dashes, no double hyphens as punctuation, no emojis in body text.
- Wrap file paths and tokens ending in `.md`, `.io`, or `.co` in backticks so Notion does not auto-link them.

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

- No monthly row: read `${CLAUDE_SKILL_DIR}/monthly-index.md` and follow "Create".
- Monthly row but no row for today: fetch the monthly page with `notion-fetch`. If its body has no `<database` tag, read `${CLAUDE_SKILL_DIR}/monthly-index.md` and follow "Add the view".

**2. Fetch today's page** with `notion-fetch` if step 1 found it. Once only.

**3. Compose the entry.** Argument text: `$ARGUMENTS`. If that is non-empty, use it verbatim as the bullets (punctuation cleanup only, no expansion) and still write the headline and metadata line from session context. Otherwise compose everything from session context using the entry shape.

**4. Write the entry.**

<condition>
  <when>Step 1 found today's page</when>

  <on-yes>
    Append with `notion-update-page`: `command: "insert_content"`, `position: {"type": "end"}`, `allow_async: false`, and `content` = `\n<empty-block/>\n` + the new callout, or the callout alone when the fetched body is empty (a page from `/journal:start-day`). If the fetched page has no icon, also pass `icon` = the callout icon. A successful response is the verification; do not fetch again.
    IMPORTANT: Never use `replace_content` (it rewrites the entire body and corrupts embedded images) or `update_content` (its string search fails on backticks).
  </on-yes>

  <on-no>
    Create with `notion-create-pages`:
    - `parent`: `{"type": "data_source_id", "data_source_id": "<the data source id>"}`
    - `properties`: `Name` = ISO date, `Tags` = `'["Work","Daily"]'`, `date:Start Date:start` = ISO date, `date:Start Date:is_datetime` = `0`
    - `icon`: the callout icon
    - `content`: the callout block
    - `allow_async`: `false`
  </on-no>
</condition>

**5. Verify a new page only.** Fetch it via `notion-fetch` and confirm the callout is present, the page icon is the callout icon, and `Start Date` equals today's ISO date. Correct any mismatch before reporting.

**6. Confirm.** Report the headline(s) written and the page URL.

<hard-rules>
  <rule>IMPORTANT: Never write callouts into monthly pages.</rule>
  <rule>Never create a daily page with empty content; an empty day page is `/journal:start-day`'s job.</rule>
</hard-rules>
