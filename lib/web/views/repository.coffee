show_components = ->
  $.get "/repository/json/components", (data) ->
    clear()
    for component in data
      fill("#content", "#t-components", {name: [component, (n) -> n.click -> show_component(component)]} )

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
# - fills templates based on key-value pairs from parameter object
# - renders single object or list of objects based on parameter count
# - supports modifier function for named fields
fill = (destId, templateId, data = {}) ->
  original_template = $($(templateId).html())
  dest = $(destId)
  if !Array.isArray(data)
    data = [data]
  clone = data.length > 1;
  # repeat for every item in data, good for rendering a list
  for item in data
    template = original_template
    if clone
      template = original_template.clone()
    fillTemplate(template, item)
    dest.append template
  if clone
    dest
  else
    template

fillTemplate = (template, item) ->
  # go throug every named key-value pair in item
  for key, values of item
    if !Array.isArray(values)
      values = [values]
    # repeat for every matching node
    for node in template.find(".#{key}")
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

$(document).ready ->
  fill("#content", "#t-components", [
      {name: [ "Alert", (node) -> node.click -> alert("foo")]},
      {name: "Abort"}
    ]
  )
