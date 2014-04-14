"use strict"

this.initRouter = ->
  router = KiRouter.router()
  router.add("/logs/show/:base/*/:id", (params) -> show_log( params.base, params.splat, params.id ))
  router.add("/logs/:base/*", (params) -> show_logs( params.base, params.splat ))
  router.add("/logs/:base", (params) -> show_log_root_base( params.base))
  router.paramVerifier = (s) -> /^[a-z0-9\/\-]+$/i.test(s)
  router.debug = true
  router.transparentRouting()
  window.router = router

clear = ->
  $("#content").empty()

this.show_log_root_base = (base) ->
  $.get "/logs/json/logs/" + base, (data) ->
    clear()
    document.title = "Logs for " + base
    renderElements "#content", "#t-log-roots",
      base: base
      data: data

this.show_logs = (base, name) ->
  $.get "/logs/json/logs/" + base + "/" + name, (data) ->
    clear()
    document.title = "Logs for " + base + "/" + name
    renderElements "#content", "#t-logs",
      base: base
      name: name
      data: data

this.show_log = (base, name, id) ->
  $.get "/logs/json/log/" + base + "/" + name + "/" + id, (data) ->
    clear()
    document.title = "Logs for " + base + "/" + name + "/" + id
    data.date = new Date(data.start * 1000).toLocaleFormat("%Y-%m-%d %H:%M:%S")
    ignore_date = new Date(data.start * 1000).toLocaleFormat("%Y-%m-%d")
    renderElements "#content", "#t-show-log",
      base: base
      name: name
      id: id
      data: data
    if data.logs
      for log in data.logs
        renderLog(log, 0, ignore_date)
    showMore()

this.renderLog = (data, level, ignore_date) ->
  if ignore_date == new Date(data.start * 1000).toLocaleFormat("%Y-%m-%d")
    data.date = new Date(data.start * 1000).toLocaleFormat("%H:%M:%S")
  else
    data.date = new Date(data.start * 1000).toLocaleFormat("%Y-%m-%d %H:%M:%S")
  indent = level * 30
  if indent < 4
    indent = 4
  data.indent = "" + (indent) + "px"
  if data.exception
    data.classes = "exception"
  appendElement "#log tr:last", "#t-log-line", data
  if data.logs
    for log in data.logs
      renderLog(log, level + 1, ignore_date)

this.showMore = ->
  for i in $(".showMore")
    item = $(i)
    text = item.text()
    arr = text.split("\n")
    if arr.length > 2
      new_text = arr[0] + "\n(" + (arr.length - 1) + " lines hidden)"
      showOnClick(i, item, text, new_text)
  for i in $(".showMoreLine")
    item = $(i)
    text = item.text()
    if text.length > 117
      new_text = text.substring(0, 100) + "... (show more)"
      showOnClick(i, item, text, new_text)


this.showOnClick = (i, item, text, new_text) ->
  i.long_text = text
  item.text(new_text)
  item.attr("title", text)
  item.click ->
    if this.long_text
      $(this).attr("title", null)
      $(this).text(this.long_text)
      delete this.long_text
