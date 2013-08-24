---
layout: default
title: Sinatra Javascript Routes and Handlebars
author: Mikko Apo
---

Ki-flow web application got refactored quite a bit. [Sinatra](http://www.sinatrarb.com/) has a wonderful
url route configuration and I rewrote the pushState support so that it supports similar mechanism.
The old templating code was replaced with Handlebars.

These changes worked out pretty well. The javascript view rendering code got a lot cleaner. There is no more .click()
binding in javascript! Instead the links between views are rendered as <a> tags. Centralized routing makes it also
a lot easier to understand how the application is structured. The change is visible in this
[commit](https://github.com/mikko-apo/ki-flow/commit/fda63d5df5c593b7e1381bc0dc7096f4751234ca),
especially in file lib/web/views/repository.coffee

The work is still in progress, but here's preliminary documentation for JavascriptRoutes:

# Sinatra routing for single page Javascript apps

Sinatra uses a powerful url based routing mechanism to identify different views from the application. Javascript
single page apps can benefit from the same by using JavascriptRoutes

Web application's HTML uses regular links to link between views

    Component: <a href="/repository/component/ki/demo">ki/demo</a>
    Version: <a href="/repository/version/ki/demo/1">ki/demo/1</a>

Routing configuration defines different urls and how they are rendered

    router = javascript_routes()
    router.add("/repository/component/*", (params) -> show_component( params.splat ))
    router.add("/repository/version/*", (params) -> show_version( params.splat ))
    router.add("/repository", (params) -> show_components( ))
    router.initPushState("/repository")

initPushState()

* registers a click handler that handles all clicks to known links
* if pushState is supported registers a window.onpopstate handler otherwise registers a handler for the hashbang links
* on start renders a view based on current url
* switches browser url between pushState and hashBang

# Features

* Supports history.pushState and hashbang (#!). Is able to convert urls between those two formats if urls are copied between browsers.
* Bookmarkable urls are easy to implement
* Clear control structure for the application
* Clear HTML
* Gracefully degrading web app (pushState -> hashBang -> no javascript)

--
24.08.2013 @ Etu-Töölö