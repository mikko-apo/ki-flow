###

Copyright 2012-2013 Mikko Apo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

###

"use strict"

# Missing features:
# - form support, catch form submits (how would this work?) get / post?
# - should route only internal addresses and skip external urls
# - relative url support
# - implement support for older browsers: setInterval and check urls
# - chrome fails when converting plain url to hashbang url: %23
# - clarify when fallbackRoute is used
# - querystring parameters as part of params
# - copy build configs from bacon.js
# - split to own repository
# - more complete sinatra path parsing, JavascriptRouteParser
# - test suite
# - documentation
# - navigate
# - go
# Known issues:
# - hashbang urls don't work in a href tags -> won't fix, use /plain/urls
# - does not resolve situation hashbang url needs to be converted and both window.location.pathname and window.location.hash are defined

if module?
  module.exports = Steward = {} # for KiRouter = require 'KiRouterjs'
  Steward.Steward = Steward # for {KiRouter} = require 'KiRouterjs'
else
  if define? and define.amd?
    define (-> Steward)
  @Steward = Steward = {} # otherwise for execution context

Steward.router = -> new StewardRoutes()

class StewardRoutes
  routes: []
  debug: false
  log: =>
    if @debug
      console.log.apply(this, arguments)
  add: (urlPattern, fn) =>
    @routes.push({route: new SinatraRouteParser(urlPattern), fn: fn, urlPattern: urlPattern})
  exec: (path) =>
    if matchedRoute = @find(path)
      @log("Found route for", path, " Calling function with params ", matchedRoute.params)
      matchedRoute.result = matchedRoute.fn(matchedRoute.params)
      return matchedRoute
  find: (path) =>
    for candidate in @routes
      if params = candidate.route.parse(path)
        return {params: params, route: candidate.matchedRoute, fn: candidate.fn, urlPattern: candidate.urlPattern}

  pushStateSupport: history && history.pushState
  hashchangeSupport: "onhashchange" of window
  hashBaseUrl: false
  previousView: false
  disableUrlUpdate: false
  fallbackRoute: false
  init: false
  initRouting: () =>
    @init = true
    try
      @attachClickListener()
      @attachLocationChangeListener()
      @renderInitialView()
    finally
      @init = false

  attachClickListener: =>
    @addListener document, "click", (event) =>
      target = event.target
      if( target && target.tagName == "A")
        if !@metakeyPressed(event) && @targetAttributeIsCurrentWindow(target)
          href = target.attributes.href.nodeValue
          @log("Processing click", href)
          if @exec(href)
            @log("New url", href)
            event.preventDefault();
            @previousView = href
            @updateUrl(href)

  metakeyPressed: (event) =>
    (event.shiftKey || event.ctrlKey || event.altKey || event.metaKey)

  targetAttributeIsCurrentWindow: (target) =>
    if !target.attributes.target
      return true
    val = target.attributes.target.nodeValue
    if ["_blank", "_parent"].indexOf(val) != -1
      return false
    if val == "_self"
      return true
    if val == "_top"
      return window.self == window.top
    return val == window.name

  attachLocationChangeListener: =>
    if @pushStateSupport
      @addListener window, "popstate", (event) =>
        href = window.location.pathname
        @log("Rendering onpopstate", href)
        @renderUrl(href)
    else
      if @hashchangeSupport
        @addListener window, "hashchange", (event) =>
          if window.location.hash.substring(0, 2) == "#!"
            href = window.location.hash.substring(2)
            if href != @previousView
              @log("Rendering onhashchange", href)
              @renderUrl(href)

  renderInitialView: =>
    @log("Rendering initial page")
    initialUrl = window.location.pathname
    forceUrlUpdate = false
    if @pushStateSupport
      if window.location.hash.substring(0, 2) == "#!" && @find(window.location.hash.substring(2))
        forceUrlUpdate = initialUrl = window.location.hash.substring(2)
    else
      if window.location.hash == "" && @find(initialUrl)
        if @hashBaseUrl && @hashBaseUrl != initialUrl
          window.location.pathname = @hashBaseUrl + "#!" + initialUrl
        else
          window.location.hash = "!" + initialUrl
      if window.location.hash.substring(0, 2) == "#!"
        initialUrl = window.location.hash.substring(2)
    @renderUrl(initialUrl)
    if forceUrlUpdate
      @updateUrl(forceUrlUpdate)

  renderUrl: (url) =>
    try
      if ret = @exec(url)
        return ret
      else
        if @fallbackRoute
          return @fallbackRoute(url)
        else
          @log("Could not resolve route for", url)
    catch err
      @log("Could not resolve route for", url, " exception", err)

  updateUrl: (href) =>
    if !@disableUrlUpdate
      if @pushStateSupport
        history.pushState({ }, document.title, href)
      else
        window.location.hash = "!" + href

  addListener: (element, event, fn) =>
    if element.addEventListener  # W3C DOM
      element.addEventListener(event, fn, false);
    else if (element.attachEvent) # // IE DOM
      element.attachEvent("on"+event, fn);
    else
      raise "addListener can not attach listeners!"

class SinatraRouteParser
  constructor: (route) ->
    @keys = []
    route = route.substring(1)
    segments = route.split("/").map (segment) =>
      match = segment.match(/((:\w+)|\*)/)
      if match
        firstMatch = match[0]
        if firstMatch == "*"
          @keys.push "splat"
          "(.*)"
        else
          @keys.push firstMatch.substring(1)
          "([^\/?#]+)"
      else
        segment
    pattern = "^/" + segments.join("/") + "$"
    #    console.log("Pattern", pattern)
    @pattern = new RegExp(pattern)
  parse: (path) =>
    i = 0
    matches = path.match(@pattern)
    #    console.log("Parse", path, matches)
    if matches
      ret = {}
      matches.slice(1).map (match) =>
        key = @keys[i]
        #        console.log("Found item", match, key)
        if ret[key]
          if !typeIsArray(ret[key])
            ret[key] = [ret[key]]
          ret[key].push(match)
        else
          ret[key]=match
        i+=1
      ret

typeIsArray = ( value ) ->
  value and
  typeof value is 'object' and
  value instanceof Array and
  typeof value.length is 'number' and
  typeof value.splice is 'function' and
  not ( value.propertyIsEnumerable 'length' )
