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
  clear()
  renderElements("#content", "#t-components-top", {components: (n) -> n.click -> show_components()})
  $.get "/repository/json/components", (data) ->
    for component in data
      renderElements("#component-list", "#t-components", {"a.name": [component, (n) -> n.click -> show_component(component)]} )

clear = ->
  $("#content").empty()

this.show_component = show_component = (component) ->
  clear()
  renderElements("#content", "#t-component", {componentName: component, components: (n) -> n.click -> show_components()})
  $.get "/repository/json/component/#{component}/versions", (data) ->
    renderElements("#version-list", "#t-version", data)

$(document).ready show_components
