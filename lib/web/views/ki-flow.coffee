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
this.assertElements = (source, assert_map) ->
  if !assert_map?
    assert_map = source
    source = $("body")
  else
    source = $(source)
  for key, asserts of assert_map
    if !Array.isArray(asserts)
      asserts = [asserts]
    nodes = source.find(key)
    selector = key
    if nodes.size() == 0
      selector = ".#{key}"
      nodes = source.find(selector)
    if asserts.length != nodes.size()
      if nodes.size() == 0
        throw "Selector '#{selector}' did not match any nodes! There are #{asserts.length} asserts."
      else
        throw "Selector '#{selector}' matched #{nodes.size()} but there are #{asserts.length} asserts."
    for i in [0..(asserts.length-1)]
      a = asserts[i]
      element = nodes.get(i)
      type = $.type(a)
      text = $(element).text()
      if type == "regexp"
        if !a.test(text)
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match RegEx '#{a}'"
      else if type == "string"
        if a != text
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match '#{a}'"
      else
        assertElements(element, a)

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
