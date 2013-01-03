show_components = ->
  $.get "/repository/json/components", (data) ->
    clear()
    for component in data
      template = $($("#t-components").html())
      a = template.find(".name")
      a.text(component)
      a.click -> show_component(component)
      $("#content").append template

clear = ->
  $("#content").empty()

show_component = (component) ->
  clear()
  template = $($("#t-component").html())
  $("#content").append template
  $(".componentName").text(component)
  $("#components").click ->
    show_components()
  show_component_versions component

show_component_versions = (component) ->
  $.get "/repository/json/component/#{component}/versions", (data) ->
    for version in data
      $("#version-list").append version.id

$(document).ready show_components