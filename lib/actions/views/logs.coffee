"use strict"

this.initRouter = ->
  router = KiRouter.router()
  router.add("/logs/show/:base/*/:id", (params) -> show_log( params.base, params.splat, params.id ))
  router.add("/logs/:base/*", (params) -> show_logs( params.base, params.splat ))
  router.add("/logs/:base", (params) -> show_log_root_base( params.base))
  router.paramVerifier = (s) -> /^[a-z0-9\/]+$/i.test(s)
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
    renderElements "#content", "#t-show-log",
      base: base
      name: name
      id: id
      data: data
    if data.logs
      for log in data.logs
        renderLog(log, 0)

this.renderLog = (data, level) ->
  data.date = new Date(data.start * 1000).toLocaleFormat("%Y-%m-%d %H:%M:%S")
  indent = level * 30
  if indent < 4
    indent = 4
  data.indent = "" + (indent) + "px"
  appendElement "#log tr:last", "#t-log-line", data
  if data.logs
    for log in data.logs
      renderLog(log, level + 1)
