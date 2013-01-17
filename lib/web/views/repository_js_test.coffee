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

$.ajaxSetup(async: false)

describe '/repository', ->
  it "/components", ->
    show_components
    assertElements
      "#component-list a": [/my\/c/, "my/product"]
  it "/component/X", ->
    show_component 'my/component'
    assertElements
      "componentName": "my/component"
      "#version-list p": "23"
    show_component 'my/product'
    assertElements
      "componentName": "my/product"
      "#version-list p": "2"
  it "/version/X", ->
    show_version 'my/product', "2"
