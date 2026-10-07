# claude-journal

A Claude Code plugin that appends a short, glanceable summary of the current session to a work journal in Notion. Run `/journal` between working sessions and move on.

Each entry is one callout per topic: a bold headline stating the outcome, a metadata line linking every ticket, PR, and branch touched, and up to four one-sentence facts. Follow-ups get their own `Next:` or `Open:` bullet so tomorrow's scan finds them.

The callout color follows the season and the icon follows the weekday, so a month of entries reads as a calendar at a glance.

| Season | Color  |   | Weekday   | Icon |
|--------|--------|---|-----------|------|
| Winter | blue   |   | Monday    | 🌙   |
| Spring | green  |   | Tuesday   | ⚔️   |
| Summer | yellow |   | Wednesday | 🪶   |
| Autumn | orange |   | Thursday  | ⚡   |
|        |        |   | Friday    | 🌸   |
|        |        |   | Saturday  | 🪐   |
|        |        |   | Sunday    | ☀️   |

## Example entry

```
**Opened PR 4 of the PROJ-7003 stack; all ACs closed except CI**
PROJ-7003 · PR 5670 · `proj-7003-import-selection`
- Rebased all four branches onto develop with no conflicts.
- PR 4 adds the import selection scope and a spec-level ledger fold.
- Next: watch CI on PR 5670.
```

## Requirements

- Claude Code.
- The Notion MCP server, added under the alias `notion`:

  ```
  claude mcp add --transport http notion https://mcp.notion.com/mcp
  ```

  A different alias works too. Set `JOURNAL_MCP_SERVER` in the config file to its name. Claude may then ask permission for the Notion tools on first use, because the skill's pre-approved tool names use the `notion` prefix; allow them once or add them to your permission rules.

## Setup

1. Install the plugin.

   ```
   /plugin marketplace add cseeman/claude-journal
   /plugin install journal@cseeman
   ```

2. Create a Notion database for the journal with these properties:

   | Property   | Type         | Notes                              |
   |------------|--------------|------------------------------------|
   | Name       | Title        | Daily pages are titled `YYYY-MM-DD` |
   | Tags       | Multi-select | Options `Work`, `Daily`, `Monthly`  |
   | Start Date | Date         | Set to the entry's date             |

3. Find the database's data source id. Ask Claude to fetch the database URL with the Notion MCP; the response contains a `collection://<uuid>` line. The uuid is the id.

4. Write the config file at `~/.config/claude-journal/config`:

   ```sh
   JOURNAL_DATA_SOURCE_ID="<uuid>"
   ```

5. Run `/journal` at the end of a session. The first run in a month also creates a monthly index page with a filtered view of that month's daily pages.

## Customizing

All customization goes in the config file, so plugin updates never overwrite it.

```sh
JOURNAL_MCP_SERVER="notion_personal"                    # if your Notion server is not aliased notion
JOURNAL_HEMISPHERE="south"                             # shifts the seasons by six months
JOURNAL_COLORS="blue_bg green_bg yellow_bg orange_bg"  # winter spring summer autumn
JOURNAL_ICONS="🌙 ⚔️ 🪶 ⚡ 🌸 🪐 ☀️"                    # Monday through Sunday
```

Colors are Notion callout backgrounds: `gray_bg`, `brown_bg`, `orange_bg`, `yellow_bg`, `green_bg`, `blue_bg`, `purple_bg`, `pink_bg`, `red_bg`.

## Usage

- `/journal` composes the entry from the session.
- `/journal <text>` uses your text as the bullets and still composes the headline and metadata line.
- `/journal:start-day` creates today's page with its properties set and nothing in the body, ready for your own notes. If the page exists, it fixes wrong `Tags` or `Start Date` and leaves the body alone.

## How it works

`today.sh` runs before the skill loads and injects the date, month label, icon, color, and data source id, so the model never computes any of them. The skill then makes three Notion calls on a normal day: search, fetch today's page, append. Creating a new daily page adds one verification fetch.

The skill follows the Agent Skills open standard, but the dynamic-context injection and pre-approved tools are Claude Code features. To use the SKILL.md with another tool, run `today.sh` yourself and paste its output in place of the Today block.

## License

MIT
