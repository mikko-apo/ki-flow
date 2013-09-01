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
# - chrome fails when converting plain url to hashbang: %23
# - querystring parameters as part of params
# - relative url support
# - copy build configs from bacon.js
# - split to own repository
# - more complete sinatra path parsing, JavascriptRouteParser
# Known issues:
# - hashbang urls don't work in a href tags -> won't fix, use /plain/urls
# - does not resolve situation where both window.location.pathname and window.location.hash are defined

if module?
  module.exports = KiRouter = {} # for KiRouter = require 'KiRouterjs'
  KiRouter.KiRouter = KiRouter # for {KiRouter} = require 'KiRouterjs'
else
  if define? and define.amd?
    define (-> KiRouter)
  @KiRouter = KiRouter = {} # otherwise for execution context

KiRouter.router = -> new KiRoutes()

class KiRoutes
  routes: []
  debug: false
  log: =>
    if @debug
      console.log.apply(this, arguments)
  add: (route, fn) =>
    @routes.push({route: new SinatraRouteParser(route), fn: fn})
  exec: (path) =>
    for candidate in @routes
      params = candidate.route.parse(path)
      if params
        @log("Found route for", path, " Calling function with params ", params)
        return candidate.fn(params)
  find: (path) =>
    for candidate in @routes
      params = candidate.route.parse(path)
      if params
        return candidate

  pushStateSupport: history && history.pushState
  hashchangeSupport: "onhashchange" of window
  hashBaseUrl: false
  disableUrlUpdate: false
  fallbackRoute: false
  initPushState: () =>
    # check if current url needs to be changed pushState <-> hashbang
    @attachClickListener()
    @attachLocationChangeListener()
    @renderInitialView()

  attachClickListener: =>
    $(document).on "click", "a", (event) =>
      target = event.target
      if !(event.shiftKey || event.ctrlKey || event.altKey || event.metaKey)
        href = target.attributes.href.nodeValue
        @log("Processing click", href)
        if @pushStateSupport
          if @exec(href)
            event.preventDefault();
            @updateUrl(href)
        else
          if @find(href)
            @log("Updating hash with", href)
            event.preventDefault();
            @updateUrl(href)

  attachLocationChangeListener: =>
    if @pushStateSupport
      window.onpopstate = (event) =>
        href = window.location.pathname
        @log("Rendering onpopstate", href)
        @renderUrl(href)
    else
      if @hashchangeSupport
        window.onhashchange = (event) =>
          href = window.location.hash.substring(2)
          @log("Rendering onhashchange", href)
          @renderUrl(href)

  renderInitialView: =>
    @log("Rendering initial page")
    initialUrl = window.location.pathname
    forceUrlUpdate = false
    if @pushStateSupport
      if window.location.hash.substring(0, 2) == "#!"
        forceUrlUpdate = initialUrl = window.location.hash.substring(2)
    else
      if @hashBaseUrl && @hashBaseUrl != window.location.pathname && window.location.hash == "" && @find(window.location.pathname)
        window.location.pathname = @hashBaseUrl + "#!" + window.location.pathname
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
