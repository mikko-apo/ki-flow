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
    showMore()

statusMapToList = (map) ->
  arr = []
  failing = 0
  ok = 0
  for key, info of map
    info_arr = []
    if info.last_failed && info.last_ok
      if info.last_failed.start > info.last_ok.start
        failing = failing + 1
        info_arr.push(info.last_failed)
        info_arr.push(info.last_ok)
      else
        ok = ok + 1
        info_arr.push(info.last_ok)
        info_arr.push(info.last_failed)
    else if info.last_failed
      failing = failing + 1
      info_arr.push(info.last_failed)
    else
      ok = ok + 1
      info_arr.push(info.last_ok)
    for i in info_arr
      i.log_root = key
      updateLog(i)
    arr.push info_arr
  arr.sort (a,b) ->
    a0 = a[0]
    b0 = b[0]
    a0_error = a0.error?
    b0_error = b0.error?
    ret = if a0_error == b0_error
      b0.start - a0.start
    else
      if a0_error then -1 else 1
    ret
  list: arr
  failing: failing
  ok: ok


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
    renderLogList data.logs, "#divLog", 0, ignore_date
    searchByText("#search", "#log tr", "#searchCount")
    if window.location.hash.length > 0
      window.location.hash = window.location.hash

renderLogList = (list, dest, level, ignore_date) ->
  if list
    now = list[0..100]
    rest = list[101..-1]
    if rest.length > 0
      setTimeout (->
        renderLogList rest, dest, level, ignore_date), 1
    for log in now
      renderLog(log, 0, ignore_date, dest)

this.searchByText = (input, row, info) ->
  $(input).change ->
    matches = 0
    searchTerm = $(this).val()
    $(row).each ->
      element = $(this)
      match = element.text().toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0
      element.toggle(match)
      if match
        matches += 1
    $(info).text(matches)

updateLog = (log) ->
  log.date = TimeFormat.formatDateTime(log.start * 1000)
  log.duration = if log.time? then TimeFormat.formatDuration(log.time * 1000) else "<i>&lt;running&gt;</i>"
  if log.exception || log.fail_reason
    log.classes = "error"
    if log.exception && log.fail_reason
      log.error = "Fail reason: #{log.fail_reason} Exception: #{log.exception}"
    else if log.exception
      log.error = "Exception: #{log.exception}"
    else
      log.error = "Fail reason: #{log.fail_reason}"

this.renderLog = (data, level, ignore_date, dest = "#divLog" ) ->
  updateLog(data)
  if ignore_date == TimeFormat.formatDate(data.start * 1000)
    data.date = TimeFormat.formatTime(data.start * 1000)
  else
    data.date = TimeFormat.formatDateTime(data.start * 1000)
  if level > 0
    data.childLog = true
  logLine = appendElement(dest, "#t-log-div", data)[0]
  showMore(logLine)
  $(".showLogs", logLine).click ->
    button = $(this)
    logs_dest = $(".childLogs", logLine)
    if button.data("rendered")
      if button.text() == "[+]"
        button.text("[-]")
        logs_dest.show()
      else
        button.text("[+]")
        logs_dest.hide()
    else
      button.data("rendered", true)
      button.text("[-]")
      renderLogList data.logs, logs_dest, level + 1, ignore_date

this.showMore = (dest="body") ->
  for i in $(".showMore", dest)
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
    showMs = true
    # round 10.5s to 11ms
    if timestamp_ms > 10000
      if (timestamp_ms % 1000) > 500
        timestamp_ms += 1000
      showMs = false
    arr = []
    if timestamp_ms > (3600 * 1000)
      arr.push Math.floor( timestamp_ms / (3600 * 1000) )
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
    if timestamp_ms > 0 && showMs
      arr.push Math.floor( timestamp_ms )
      arr.push "ms"
    arr.join("")
