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
# - copy build configs from bacon.js
# - finish hashbang support
# - hashbang <-> pushState conversion
# - relative url support
# - querystring parameters as part of params
# - split to own repository
# - more complete sinatra path parsing, JavascriptRouteParser

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

  pushStateSupport: history && history.pushState
  disableUrlUpdate: false
  fallbackRoute: false
  initPushState: (hashFallBack) =>
    # check if current url needs to be changed pushState <-> hashbang
    # attach click listener
    $(document).on "click", "a", (event) =>
      target = event.target
      if !(event.shiftKey || event.ctrlKey || event.altKey || event.metaKey)
        href = target.attributes.href.nodeValue
        @log("Rendering click", href)
        if @exec(href)
          event.preventDefault();
          if !@disableUrlUpdate
            if @pushStateSupport
              history.pushState({ }, document.title, href)
            else
              window.location.hash=href
    # attach pushstateListener
    if @pushStateSupport
      window.onpopstate = (event) =>
        @log("Rendering onpopstate", @getCurrentUrl())
        @renderCurrentUrl()
    @log("Rendering initial page")
    @renderCurrentUrl()

  renderUrl: (url) =>
    try
      if ret = @exec(url)
        return ret
      else
        if @fallbackRoute
          return @fallbackRoute()
        else
          @log("Could not resolve route for", url)
    catch err
      @log("Could not resolve route for", url, " exception", err)

  renderCurrentUrl: =>
    @renderUrl(@getCurrentUrl())

  getCurrentUrl: =>
    if @pushStateSupport
      window.location.pathname
    else
      window.location.hash

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
