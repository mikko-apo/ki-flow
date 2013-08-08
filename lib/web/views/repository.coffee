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

clear = ->
  $("#content").empty()

pushState = (restore, push_command, push_args, title, url) ->
  if !restore && !test?
    stateObj = { restore: push_command, args: push_args }
    history.pushState(stateObj, title, url)
  document.title = title

this.show_components = (restore) ->
  $.get "/repository/json/components", (data) ->
    clear()
    pushState restore, "show_components", [], "All components", "/repository"
    renderElements "#content", "#t-components-top",
      components: (n) -> n.click -> show_components()
    renderElements "#component-list", "#t-components", data.map (component) ->
      "a.name": [component, (n) -> n.click -> show_component(component)]

this.show_component = (component, restore) ->
  $.get "/repository/json/component/#{component}/versions", (data) ->
    clear()
    pushState restore, "show_component", [component], component, "/repository/component/#{component}"
    # #fi-component template contains two elements:
    # - .componentName
    # - .components is a link back to main page
    renderElements "#content", "#t-component",
      componentName: component
      components: (n) -> n.click -> show_components()
    # data is a list of versions: {"id": "2","time": "2013-01-03 00:31:33 +0200"}
    renderElements "#version-list", "#t-version", data, (k, v, n) -> n.click -> show_version(component, v)

this.show_version = (component, version, restore) ->
  if !version
    arr = component.split("/")
    component = arr[0..-2].join("/")
    version = arr[arr.length-1]
  $.get "/repository/json/version/#{component}/#{version}/metadata", (metadata) ->
    clear()
    pushState restore, "show_version", [component, version], "#{component}/#{version}", "/repository/version/#{component}/#{version}"
    renderElements "#content", "#t-version-top",
      versionName: version
      componentName: [component, (n) -> n.click -> show_component(component)]
      components: (n) -> n.click -> show_components()
      version_id: metadata.version_id
    if metadata.files
      renderElements "#version-files", "#t-version-file", metadata.files
    if metadata.dependencies
      renderElements "#dependencies", "#t-version-dependency", metadata.dependencies.map (d) ->
        id = d.version_id
        d.version_id = [id, (n) -> n.click -> show_version(id)]
        d
    $.get "/repository/json/version/#{component}/#{version}/status", (status) ->
      renderElements "#statuses", "#t-version-status", status.map (s) ->
        status: s[0]
        value: s[1]

window.onpopstate = (event) ->
  if (event.state)
    window[event.state.restore](event.state.args..., true);
