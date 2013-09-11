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

this.initRouter = ->
  router = Steward.router()
  router.add("/repository/component/*", (params) -> show_component( params.splat ))
  router.add("/repository/version/*", (params) -> show_version( params.splat ))
  router.add("/repository", (params) -> show_components( ))
  router.fallbackRoute = (url) -> alert("Unknown matchedRoute: " + url);
  router.hashBaseUrl="/repository"
#  router.pushStateSupport = false
  router.debug = true
  router.initRouting()
  window.router = router

clear = ->
  $("#content").empty()

this.show_components = ->
  $.get "/repository/json/components", (data) ->
    clear()
    document.title = "All components"
    renderElements "#content", "#t-all-components", data

this.show_component = (component) ->
  $.get "/repository/json/component/#{component}/versions", (data) ->
    clear()
    document.title = component
    renderElements "#content", "#t-component",
      componentName: component,
      versions: data

this.show_version = (component, version) ->
  if !version
    arr = component.split("/")
    component = arr[0..-2].join("/")
    version = arr[arr.length-1]
  $.get "/repository/json/version/#{component}/#{version}/metadata", (metadata) ->
    $.get "/repository/json/version/#{component}/#{version}/status", (status) ->
      clear()
      document.title = "#{component}/#{version}"
      metadata.versionName = version
      metadata.componentName = component
      metadata.status = status.map (s) ->
        status: s[0],
        value: s[1]
      renderElements "#content", "#t-version-top", metadata
