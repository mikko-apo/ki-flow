"use strict"

describe '/repository', ->
  it "/components", ->
    show_components
    assertElements({"#component-list a": [/my\/c/, "my/product"]})
  it "/component/X", ->
    show_component 'my/component'
    assertElements({"#version-list p": "23"})
    show_component 'my/product'
    assertElements({"#version-list p": "2"})
