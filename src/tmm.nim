{.experimental: "codeReordering".}
include karax/prelude

setRenderer createDom

type tabRow = tuple
  # TODO: favicon
  title: string
  checked: bool

var tabRows: seq[tabRow] = @[
  (title: "hello 1", checked: false),
  (title: "rather longer entry", checked: true),
]

proc createDom(): VNode =
  buildHtml(tdiv):
    table:
      for i, row in tabRows.mpairs:
        tr:
          td:
            text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row))

proc toggle(row: var tabRow): proc() =
  return proc() =
    row.checked = not row.checked
