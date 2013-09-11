---
layout: default
title: Sinatra Javascript Routes and Handlebars
author: Mikko Apo
---

# Refactoring the web app

Ki-flow web application got refactored quite a bit. [Sinatra](http://www.sinatrarb.com/) has a wonderful
url route configuration API. I rewrote the pushState support so that it has a similar syntax.
Also the old templating code was replaced with Handlebars.

These changes worked out pretty well. The javascript view rendering code got a lot cleaner. There is no more .click()
binding in javascript! Instead the links between views are rendered as &lt;a> tags. Centralized routing makes it also
a lot easier to understand how the application is structured. The change is visible in this
[commit](https://github.com/mikko-apo/ki-flow/commit/fda63d5df5c593b7e1381bc0dc7096f4751234ca),
especially in file lib/web/views/repository.coffee

The files related to the single page app are:

* [lib/web/views/repository.coffee](https://github.com/mikko-apo/ki-flow/blob/master/lib/web/views/repository.coffee) - Route config, front code for ajax calls and view rendering
* [lib/web/views/Steward.coffee](https://github.com/mikko-apo/ki-flow/blob/master/lib/web/views/Steward.coffee) - JavascriptRoutes
* [lib/web/views/repository_page.erb](https://github.com/mikko-apo/ki-flow/blob/master/lib/web/views/repository_page.erb) - Handlebar templates
* [lib/web/repository.rb](https://github.com/mikko-apo/ki-flow/blob/master/lib/web/repository.rb) - last two Sinatra controller methods serve the pages and trigger init_router()
* [lib/web/views/ki-flow.coffee](https://github.com/mikko-apo/ki-flow/blob/master/lib/web/views/ki-flow.coffee) - Handlebars rendering

The work is still in progress and here's preliminary documentation for JavascriptRoutes:

# Sinatra routing for single page Javascript apps

Sinatra uses a powerful url based routing mechanism to identify different views in the application. Javascript
single page apps can benefit from the same by using JavascriptRoutes

Web application's HTML uses regular links to link between views

    Component: <a href="/repository/component/ki/demo">ki/demo</a>
    Version: <a href="/repository/version/ki/demo/1">ki/demo/1</a>

Routing configuration defines different urls and how they are rendered

    router = KiRouter.router()
    router.add("/repository/component/*", (params) -> show_component( params.splat ))
    router.add("/repository", (params) -> show_components( ))
    router.add("/say/*/to/:name", (params) -> say_hello( params.splat, params.name ))
    router.fallbackRoute = (url) -> alert("Unknown route: " + url);
    router.hashBaseUrl = "/repository"
    router.initPushState()

initPushState()

* registers a click handler that handles all clicks to known links
* if pushState is supported registers a window.onpopstate handler otherwise registers a handler for the hashbang links
* switches browser url between pushState and hashBang if needed
* renders a view based on current url

# Features

* Supports history.pushState and hashbang (#!). Is able to convert urls between those two formats if urls are copied between browsers.
* Bookmarkable urls are easy to implement
* Provides a centralized control structure for the application
* Removes the need to bind view change listeners in javascript
* Plain HTML with regular a href links
* Gracefully degrading web app (pushState -> hashBang -> no javascript)
* Supports ctrl, shift, alt and meta keys so users can open new tabs and windows easily
* Attaches listener to document level, does not interfere with events handled by application

--
24.08.2013 @ Etu-Töölö