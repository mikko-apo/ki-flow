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
window.router.disableUrlUpdate=true

describe "SinatraJavascriptRoutes", ->
  it "should execute operation based on matched route", ->
    router = sinatra_routes()
    router.add("/one-name/:name", (params) -> ["one-name", params.name] )
    router.exec("/one-name/mikko").should.deep.equal [ 'one-name', 'mikko' ]
    router.add("/two-name/:nameA/:nameB", (params) -> ["two-name", params.nameA, params.nameB] )
    router.exec("/two-name/mikko/apo").should.deep.equal [ 'two-name', 'mikko', "apo" ]
    router.add("/double-name/:name/:name", (params) -> ["double-name", params.name] )
    router.exec("/double-name/mikko/apo").should.deep.equal [ 'double-name', ['mikko', "apo"] ]
    router.add("/foo/*", (params) -> ["foo", params.splat] )
    router.add("/multi/:name/*", (params) -> ["multi", params.name, params.splat] )
    router.add("/reverse-multi/*/:name", (params) -> ["reverse-multi", params.splat, params.name] )
    router.exec("/foo/mikko").should.deep.equal [ 'foo', 'mikko' ]
    router.exec("/foo/mikko/bar").should.deep.equal [ 'foo', 'mikko/bar' ]
    router.exec("/multi/mikko/bar").should.deep.equal [ 'multi', 'mikko', 'bar' ]
    router.exec("/multi/mikko/foo/bar").should.deep.equal [ 'multi', 'mikko', 'foo/bar' ]
    router.exec("/reverse-multi/bar/mikko").should.deep.equal [ 'reverse-multi', 'bar', 'mikko' ]
    router.exec("/reverse-multi/foo/bar/mikko").should.deep.equal [ 'reverse-multi', 'foo/bar' ,'mikko' ]

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
    $("#version-list a").click()
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
    $("#dependencies a").click()
    document.title.should.equal "my/component/23"
    assertElements
      "#version-files":
        path: "test.sh"
        ".size": "2"
      "#statuses":
        status: "Smoke"
        value: "Green"