# Monthly index page

Read this only when the lookup calls for it. "The data source" is the id from the Today block.

## Create

**A.** `notion-create-pages` with `parent` = `{"type": "data_source_id", "data_source_id": "<the data source id>"}`, `Name` = month label, `Tags` = `["Work","Monthly"]`, `allow_async` = `false`, and `content`:
```
<table-of-contents color="gray" />
# Daily Entries
<empty-block/>
```

**B.** Go to "Add the view" below with the page id returned by step A.

## Add the view

`notion-create-view`, which places a linked view on the page:
- `parent_page_id`: the monthly page id
- `data_source_id`: the data source
- `name`: `<MonthName> <YYYY> Daily Entries`
- `type`: `"table"`
- `configure`: `FILTER "Tags" CONTAINS "Daily" AND "Start Date" >= "YYYY-MM-01" AND "Start Date" <= "YYYY-MM-LAST"; SORT BY "Start Date" DESC`

If this call fails, report it with the monthly page URL and continue.
