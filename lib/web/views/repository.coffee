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

this.show_components = show_components = ->
  $.get "/repository/json/components", (data) ->
    clear()
    renderElements "#content", "#t-components-top",
      components: (n) -> n.click -> show_components()
    for component in data
      renderElements "#component-list", "#t-components",
        "a.name": [component, (n) -> n.click -> show_component(component)]

clear = ->
  $("#content").empty()

this.show_component = (component) ->
  $.get "/repository/json/component/#{component}/versions", (data) ->
    clear()
    # #fi-component template contains two elements:
    # - .componentName
    # - .components is a link back to main page
    renderElements "#content", "#t-component",
      componentName: component
      components: (n) -> n.click -> show_components()
    # data is a list of versions: {"id": "2","time": "2013-01-03 00:31:33 +0200"}
    renderElements "#version-list", "#t-version", data, (k, v, n) -> n.click -> show_version(component, v)

this.show_version = (component, version) ->
  if !version
    arr = component.split("/")
    component = arr[0..-2].join("/")
    version = arr[arr.length-1]
  $.get "/repository/json/version/#{component}/#{version}/metadata", (metadata) ->
    clear()
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

$(document).ready show_components
