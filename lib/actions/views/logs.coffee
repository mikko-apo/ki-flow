"use strict"

this.initRouter = ->
  router = KiRouter.router()
  router.add("/logs/show/:base/*/:id", (params) -> show_log( params.base, params.splat, params.id ))
  router.add("/logs/:base/*", (params) -> show_logs( params.base, params.splat ))
  router.add("/logs/:base", (params) -> show_log_root_base( params.base))
  router.paramVerifier = (s) -> /^[a-z0-9\/\-]+$/i.test(s)
#  router.debug = true
  router.transparentRouting()
  window.router = router

clear = ->
  $("#content").empty()

this.show_log_root_base = (base) ->
  $.get "/logs/json/status/" + base, (data) ->
    clear()
    document.title = "Logs for " + base
    renderElements "#content", "#t-logs-status",
      base: base
      data: statusMapToList(data)

statusMapToList = (map) ->
  arr = []
  for key, info of map
    info_arr = []
    if info.last_failed && info.last_ok
      if info.last_failed.start > info.last_ok.start
        info_arr.push(info.last_failed)
        info_arr.push(info.last_ok)
      else
        info_arr.push(info.last_ok)
        info_arr.push(info.last_failed)
    else if info.last_failed
      info_arr.push(info.last_failed)
    else
      info_arr.push(info.last_ok)
    for i in info_arr
      i.log_root = key
      updateLog(i)
    arr.push info_arr
  arr.sort (a,b) ->
    a0 = a[0]
    b0 = b[0]
    a0_error = (a0.exception || a0.fail_reason)
    ret = if a0_error == (b0.exception || b0.fail_reason)
      b0.start - a0.start
    else
      if a0_error then -1 else 1
    ret
  arr


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
    ignore_date = TimeFormat.formatDate(data.start * 1000)
    updateLog(data)
    renderElements "#content", "#t-show-log",
      base: base
      name: name
      id: id
      data: data
    if data.logs
      for log in data.logs
        renderLog(log, 0, ignore_date)
    showMore()

updateLog = (log) ->
  log.date = TimeFormat.formatDateTime(log.start * 1000)
  log.duration = if log.time then TimeFormat.formatDuration(log.time * 1000) else "<i>&lt;running&gt;</i>"
  if log.exception || log.fail_reason
    log.classes = "error"
    if log.exception && log.fail_reason
      log.error = "Fail reason: #{log.fail_reason} Exception: #{log.exception}"
    else if log.exception
      log.error = "Exception #{log.exception}"
    else
      log.fail_reason = "Fail reason: #{log.fail_reason}"

this.renderLog = (data, level, ignore_date) ->
  updateLog(data)
  if ignore_date == TimeFormat.formatDate(data.start * 1000)
    data.date = TimeFormat.formatTime(data.start * 1000)
  else
    data.date = TimeFormat.formatDateTime(data.start * 1000)
  indent = level * 30
  if indent < 4
    indent = 4
  data.indent = "" + (indent) + "px"
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

class TimeFormat
  @formatTime = (timestamp_ms) ->
    new Date(parseInt(timestamp_ms)).toLocaleTimeString()

  @formatDate = (timestamp_ms) ->
    new Date(parseInt(timestamp_ms)).toLocaleDateString()

  @formatDateTime = (timestamp_ms) ->
    "#{@formatDate(timestamp_ms)} #{@formatTime(timestamp_ms)}"

  @formatDuration = (timestamp_ms) ->
    if timestamp_ms == 0
      return "0ms"
    arr = []
    if timestamp_ms > (3600 * 1000)
      arr.push Math.floor( sec / (3600 * 1000) )
      arr.push "h"
    timestamp_ms %= (3600 * 1000)
    if timestamp_ms > (60 * 1000)
      arr.push Math.floor( timestamp_ms / (60 * 1000) )
      arr.push "m"
    timestamp_ms %= (60 * 1000)
    if timestamp_ms > (1000)
      arr.push Math.floor( timestamp_ms / (1000) )
      arr.push "s"
    timestamp_ms %= (1000)
    if timestamp_ms > 0
      arr.push Math.floor( timestamp_ms )
      arr.push "ms"
    arr.join("")
