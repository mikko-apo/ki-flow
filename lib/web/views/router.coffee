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

typeIsArray = ( value ) ->
  value and
  typeof value is 'object' and
  value instanceof Array and
  typeof value.length is 'number' and
  typeof value.splice is 'function' and
  not ( value.propertyIsEnumerable 'length' )

class SinatraJavascriptRouteParser
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
    pattern = "^/" + segments.join("/")
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

class SinatraJavascriptRoutes
  routes: []
  debug: false
  log: =>
    if @debug
      console.log.apply(this, arguments)
  add: (route, fn) =>
    @routes.push({route: new SinatraJavascriptRouteParser(route), fn: fn})
  exec: (path) =>
    for candidate in @routes
      params = candidate.route.parse(path)
      if params
        @log("Found route for", path, " Calling function with params ", params)
        return candidate.fn(params)

  pushStateSupport: history && history.pushState
  disableUrlUpdate: false
  initPushState: (hashFallBack) =>
    # check if current url needs to be changed pushState <-> hashbang
    # attach click listener
    $("body").click (event) =>
      target = event.target
      if target.nodeName == "A"
        href = target.attributes.href.nodeValue
        @log("Click for", href)
        try
          if @exec(href)
            event.preventDefault();
            @log("Click for", href, "rendered")
            if !@disableUrlUpdate
              if @pushStateSupport
                history.pushState({ }, document.title, href)
              else
                window.location.hash=href
          else
            @log("Could not resolve route for", href)
        catch err
          @log("Could not resolve route for", href, " exception", err)
    # attach pushstateListener
    if @pushStateSupport
      window.onpopstate = (event) =>
        @log("Rendering pushState change", @getCurrentUrl())
        @renderCurrentUrl()
    @renderCurrentUrl()

  renderCurrentUrl: =>
    @exec(@getCurrentUrl())

  getCurrentUrl: =>
    if @pushStateSupport
      window.location.pathname
    else
      window.location.hash

this.sinatra_routes = -> new SinatraJavascriptRoutes()
