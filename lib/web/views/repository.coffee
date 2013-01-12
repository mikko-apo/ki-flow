show_components = ->
  clear()
  fill("#content", "#t-components-top", {components: (n) -> n.click -> show_components()})
  $.get "/repository/json/components", (data) ->
    for component in data
      fill("#component-list", "#t-components", {"a.name": [component, (n) -> n.click -> show_component(component)]} )

clear = ->
  $("#content").empty()

show_component = (component) ->
  clear()
  fill("#content", "#t-component", {componentName: component, components: (n) -> n.click -> show_components()})
  $.get "/repository/json/component/#{component}/versions", (data) ->
    fill("#version-list", "#t-version", data)

$(document).ready show_components

# simple templating mechanism that handles
# - templates from script tags
# - fills templates based on key-value pairs from parameter object, lookup either class (property name) or jquery selector string (string)
# - renders single object or list of objects based on parameter count
# - supports modifier function for named fields
fill = (destId, templateId, data = {}) ->
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
    if $.type(key) == "string"
      selector = key
    else
      selector = ".#{key}"
    # repeat for every matching node
    for node in template.find(selector)
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
