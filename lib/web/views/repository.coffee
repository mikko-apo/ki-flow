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

# simple templating mechanism that handles
# - templates from script tags
# - fills templates based on key-value pairs from parameter object, lookup either class (property name) or jquery selector string (string)
# - renders single object or list of objects based on parameter count
# - supports modifier function for named fields
renderElements = (destId, templateId, data = {}) ->
  if !Array.isArray(data)
    data = [data]
  clone = true
  template_source = $(templateId)
  if template_source.is("script")
    original_template = $("<div>"+template_source.html()+"</div>")
    clone = data.length > 1
  else
    original_template = template_source
  # repeat for every item in data, good for rendering a list
  dest = $(destId)
  for item in data
    template = original_template
    if clone
      template = original_template.clone()
    fillTemplate(template, item)
    for i in template.children()
      dest.append i
  if clone
    dest
  else
    template

fillTemplate = (template, item) ->
  # go throug every named key-value pair in item
  for key, values of item
    if !Array.isArray(values)
      values = [values]
    nodes = template.find(key)
    if nodes.size() == 0
      nodes = template.find(".#{key}")
    # repeat for every matching node
    for node in nodes
      fillNode(node, values)

fillNode = (node, values) ->
  node = jQuery(node)
  for value in values
    type = $.type(value)
    # modifier function is applied to the selected node
    if type == "function"
      value(node)
    # object's values are applied to the selected node
#    if type == "object"
#      fillNode(node, value)
     # each item in array generates a new child
#    if type == "array"
#      parent = node.parent()
#      node.detach()
#      for data in value
#        newNode = node.clone()
#        fillNode(newNode, data)
#        parent.append(newNode)
    # other values are set as text
    else
      node.text value

#$(document).ready ->
#  fill("#content", "#t-components", [
#      {name: [ "Alert", (node) -> node.click -> alert("foo")]},
#      {name: "Abort"}
#    ]
#  )

this.assertElements = (assert_map) ->
  for key, asserts of assert_map
    if !Array.isArray(asserts)
      asserts = [asserts]
    nodes = $(key)
    selector = key
    if nodes.size() == 0
      selector = ".#{key}"
      nodes = $(selector)
    if asserts.length != nodes.size()
      throw "Selector '#{selector}' matched #{nodes.size()} but there are #{asserts.length} asserts."
    for i in [0..(asserts.length-1)]
      a = asserts[i]
      element = nodes.get(i)
      type = $.type(a)
      text = $(element).text()
      if type == "regexp"
        if !a.test(text)
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match RegEx '#{a}'"
      else
        if a != text
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match '#{a}'"