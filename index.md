---
layout: default
title: ki-flow blog
---

### ki-flow

A Continuous Integration and Continuous Delivery platform.

### Warning

*note:* Currently ki-flow is not ready for public use.

### Plan

1. Package repository - local features done, additional features need to be implemented
2. Web-UI - Barebones version works
3. CI-scripts - ki.yml based build works, product build works
4. Supervisor - launches processes (web, ci) and monitors them

### Posts

<ul>
{% for post in site.posts %}
<li><a href="{{ post.url }}">{{ post.title }}</a> - {{post.author}} - {{ post.date | date_to_string }}</li>
{% endfor %}
</ul>

### Documentation

<ul>
  <li>
    ki-flow uses <a href="https://github.com/mikko-apo/ki-repo">ki-repo</a> extensively.
    ki-repo is a file system based package repository, more information is available here: <a href="/ki-repo-doc">ki-repo documentation</a>
  </li>
</ul>
