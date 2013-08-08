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
this.test = true

describe '/repository', ->

  it "/components", ->
    show_components()
    document.title.should.equal "All components"
    assertElements
      "#component-list a": [/my\/c/, "my/product"]
    $("#component-list a")[0].click()
    document.title.should.equal "my/component"
    show_components()
    $("#component-list a")[1].click()
    document.title.should.equal "my/product"

  it "/component/X", ->
    show_component 'my/component'
    document.title.should.equal "my/component"
    assertElements
      "componentName": "my/component"
      "#version-list .id": "23"
    show_component 'my/product'
    assertElements
      "componentName": "my/product"
      "#version-list .id": "2"
    $("#version-list .id").click()
    document.title.should.equal "my/product/2"

  it "/version/X", ->
    show_version 'my/product', "2"
    document.title.should.equal "my/product/2"
    assertElements
      "#version-files":
        path: "readme.txt"
        ".size": "2"
      "#dependencies":
        "version_id": "my/component/23"
        "name": "comp"
        "path": "comp"
    # check dependency and status
    $(".version_id").click()
    document.title.should.equal "my/component/23"
    assertElements
      "#version-files":
        path: "test.sh"
        ".size": "2"
      "#statuses":
        status: "Smoke"
        value: "Green"