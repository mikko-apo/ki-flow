---
layout: default
title: ki-flow blog
---

### ki-flow

A Continuous Integration and Continuous Delivery platform.

### Warning

*note:* Currently ki-flow is not ready for public use. Hopefully during the spring of 2013 it will be ready for
public use.

### Plan

1. Package repository - local features done, additional features need to be implemented
2. CI-scripts and Web-UI - missing at the moment

### Posts

<ul>
{% for post in site.posts %}
<li><a href="{{ post.url }}">{{ post.title }}</a> - {{post.author}} - {{ post.date | date_to_string }}</li>
{% endfor %}
</ul>

