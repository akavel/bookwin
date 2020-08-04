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
    for i, row in tabRows.pairs:
      input(`type`="checkbox", checked=toChecked(tabRows[i].checked), id="box" & $i):
        proc onchange() =
          tabRows[i].checked = not tabRows[i].checked
    # table:
    #   # for i, row in tabRows.mpairs:
    #   #   tr(id="row" & $i):
    #   #     # td:
    #   #     #   text row.title
    #   #     td(id="cell" & $i):
    #   #       form(id="form" & $i):
    #   #         input(`type`="checkbox", checked=toChecked(row.checked), id="box" & $i):
    #   #           proc onchange() =
    #   #             row.checked = not row.checked
    #   #             # tabRows[i].checked = not tabRows[i].checked

    # button:
    #   text "Say hello..."
    #   proc onclick(ev: Event, n: VNode) =
    #     lines.add "Hello mello"
    # for l in lines:
    #   tdiv:
    #     text l
    # # text "Hello karax world!"
