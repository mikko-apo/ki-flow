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

describe "KiRouter", ->
  it "should execute operation based on matched matchedRoute", ->
    router = KiRouter.router()
    router.add("/one-name/:name", (params) -> ["one-name", params.name] )
    router.exec("/one-name/mikko").result.should.deep.equal [ 'one-name', 'mikko' ]
    router.add("/two-name/:nameA/:nameB", (params) -> ["two-name", params.nameA, params.nameB] )
    router.exec("/two-name/mikko/apo").result.should.deep.equal [ 'two-name', 'mikko', "apo" ]
    router.add("/double-name/:name/:name", (params) -> ["double-name", params.name] )
    router.exec("/double-name/mikko/apo").result.should.deep.equal [ 'double-name', ['mikko', "apo"] ]
    router.add("/foo/*", (params) -> ["foo", params.splat] )
    router.add("/multi/:name/*", (params) -> ["multi", params.name, params.splat] )
    router.add("/reverse-multi/*/:name", (params) -> ["reverse-multi", params.splat, params.name] )
    router.exec("/foo/mikko").result.should.deep.equal [ 'foo', 'mikko' ]
    router.exec("/foo/mikko/bar").result.should.deep.equal [ 'foo', 'mikko/bar' ]
    router.exec("/multi/mikko/bar").result.should.deep.equal [ 'multi', 'mikko', 'bar' ]
    router.exec("/multi/mikko/foo/bar").result.should.deep.equal [ 'multi', 'mikko', 'foo/bar' ]
    router.exec("/reverse-multi/bar/mikko").result.should.deep.equal [ 'reverse-multi', 'bar', 'mikko' ]
    router.exec("/reverse-multi/foo/bar/mikko").result.should.deep.equal [ 'reverse-multi', 'foo/bar' ,'mikko' ]

describe "assertElements", ->
#  it "should support 2 parameters: selector + (assert array)", ->
#    assertElements "h3", "Components"
#    assertElements "#component-list a", ["ki/sbt", /demo/,"ki/product"]
#    (-> assertElements "#component-list a", "ki/sbt", "demo2").should.throw("Selector \'h3\' returned 3 elements. Item at index 0 \'Components\' does not match String \'demo2\'")
#  it "should support n parameters: selector + asserts", ->
#    assertElements "h3", "Components"
#    assertElements "#component-list a", "ki/sbt", /demo/,"ki/product"
#    (-> assertElements "#component-list a", "ki/sbt", "demo2").should.throw("Selector \'h3\' returned 3 elements. Item at index 0 \'Components\' does not match String \'demo2\'")
#  it "should support two parameters: source + assertMap", ->
#    assertElements "#component-list", {a: ["ki/sbt", /demo/,"ki/product"]}
#  it "should support nested assertMaps", ->
#    assertElements
#      "#component-list":
#        a: ["ki/sbt", /demo/,"ki/product"]
  it "should support property as selector", ->
    assertElements h3: "Components"
    (-> assertElements h3: "aa").should.throw("Selector \'h3\' returned 1 elements. Item at index 0 \'Components\' does not match String \'aa\'")
  it "should handle string assert", ->
    assertElements "h3": "Components"
    (-> assertElements "h3": "aa").should.throw("Selector \'h3\' returned 1 elements. Item at index 0 \'Components\' does not match String \'aa\'")
  it "should handle regex assert", ->
    assertElements "h3": /Comp/
    (-> assertElements "h3": /aa/).should.throw("Selector \'h3\' returned 1 elements. Item at index 0 \'Components\' does not match RegEx \'/aa/\'")
  it "should handle function assert", ->
    assertElements "h3": (txt) -> txt.should.equal("Components")
    (-> assertElements "h3": (txt) -> txt.should.equal("aa")).should.throw("Selector \'h3\' returned 1 elements. Item at index 0 \'Components\' does not pass function: expected \'Components\' to equal \'aa\'")
#  it "should handle array of asserts", ->
#    assertElements "#component-list a": ["ki/sbt", /demo/,"ki/product"]
#    (-> assertElements "#component-list a": ["ki/sbt","foo"]).should.throw("Selector \'#component-list a\' returned 3 elements. Item at index 1 \'demo/result\' does not match String \'foo\'")
#  it "should try adding comma to selector", ->
#    assertElements name: ["ki/sbt", /demo/,"ki/product"]
#    assertElements "name": ["ki/sbt", /demo/,"ki/product"]
#    assertElements ".name": ["ki/sbt", /demo/,"ki/product"]
#    (-> assertElements name: ["ki/sbt2"]).should.throw("Selector \'.name\' returned 3 elements. Item at index 0 \'ki/sbt\' does not match String \'ki/sbt2\'")
  it "should warn about no parameters", ->
  it "should warn if selector does not match any elements", ->
    (-> assertElements h4: "a").should.throw("Selector \'h4\' did not match any elements! There are 1 asserts!")
#  it "should warn if too many or too few asserts", ->
#    (-> assertElements name: ["ki/sbt"]).should.throw("Selector \'.name\' returned 3 elements. There were 1 asserts. 1 elements were ok, but you need to add 2 asserts!")
#    (-> assertElements name: ["ki/sbt", /demo/,"ki/product", "foo"]).should.throw("Selector \'.name\' returned 3 elements. There were 4 asserts. 3 elements were ok, but you need to remove 1 asserts!")

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
    $("#version-list a")[0].click()
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
    $("#dependencies a")[0].click()
    document.title.should.equal "my/component/23"
    assertElements
      "#version-files":
        path: "test.sh"
        ".size": "2"
      "#statuses":
        status: "Smoke"
        value: "Green"