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

# simple assert method which checks key-value pairs from a Hash
# - makes it easy to check many items from page
# - Hash key is used as jquery selector
# - value can contain either one item or a list of values. selector needs to find the same number of elements
# - value can contain either strings or regex objects
# TODO:
# - support for function assertions
# - documentation
# - split to own repo
# - tests
@assertElements = (source, assert_map) ->
  if !assert_map?
    assert_map = source
    source = "body"
  source = $(source)
  for key, asserts of assert_map
    nodes = source.find(key)
    selector = original_key = key
    if nodes.size() == 0
      selector = ".#{key}"
      try
        nodes = source.find(selector)
      catch error
      finally
        if nodes.size() == 0
          selector = original_key
    if !Array.isArray(asserts)
      if asserts.callee?
        # convert argument parameters to an array
        asserts = Array.prototype.slice.call(asserts)
      else
        asserts = [asserts]
    assertCount = asserts.length
    nodeCount = nodes.size()
    if assertCount > 0 && nodeCount == 0
      throw "Selector '#{selector}' did not match any elements! There are #{assertCount} asserts!"
    numberOfCompared = Math.min(assertCount, nodeCount)
    for i in [0..numberOfCompared-1]
      a = asserts[i]
      element = nodes.get(i)
      type = $.type(a)
      text = $(element).text()
      err = "Selector '#{selector}' returned #{nodeCount} elements. Item at index #{i} '#{text}' "
      if type == "regexp"
        if !a.test(text)
          throw  err + "does not match RegEx '#{a}'"
      else if type == "string"
        if a != text
          throw err + "does not match String '#{a}'"
      else if type == "function"
        try
          a(text)
        catch error
          error.message = err + "does not pass function: " + error.message
          throw error
      else
        assertElements(element, a)
    diff = nodeCount - assertCount
    if diff != 0
      verb = if diff > 0 then "add" else "remove"
      throw "Selector '#{selector}' returned #{nodeCount} elements. There were #{assertCount} asserts. #{numberOfCompared} elements were ok, but you need to #{verb} #{Math.abs(diff)} asserts!"
  null # cleaner javascript

handlebarsCache = {}

getCompiledTemplate = (templateId) ->
  compiledTemplate = handlebarsCache[templateId]
  if compiledTemplate
    return compiledTemplate
  template = $(templateId)
  if template.size() == 0
    throw "Could not locate template '#{templateId}'"
  handlebarsCache[templateId] = Handlebars.compile(template.html())

this.renderElements = (destId, templateId, data) ->
  dest = $(destId)
  if dest.size() == 0
    throw "Could not locate destination '#{destId}'"
  dest.html(getCompiledTemplate(templateId)(data));

this.appendElement = (destId, templateId, data) ->
  dest = $(destId)
  if dest.size() == 0
    throw "Could not locate destination '#{destId}'"
  dest.after(getCompiledTemplate(templateId)(data));
