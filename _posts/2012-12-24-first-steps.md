---
layout: default
title: First steps to better Continuous Integration tools
author: Mikko Apo
---

# First steps to better Continuous Integration tools

## Step 1 - Repository

The first month and the first part of the project was to implement the basic
functionality for the package repository. Now local features work, the repository
has command line utilities, Ruby API and documentation in multiple formats.

The repository supports basic repository operations like build package, import, export,
test and search. In addition to those there is already support for defining
dependencies between package versions and setting statuses for package versions.

There is still a long list of features that need to be implemented and
the repository is not ready or even stable at the moment.

The repository has been published as a rubygem: [ki-repo](https://rubygems.org/gems/ki-repo).

To get the CI features working, two other parts need to be implemented. CI-scripts
will contains functionality for

## Steps 2 & 3 - CI-scripts and Web-UI

CI-scripts and Web-UI will be done at the same time, as they complement each other.
Also some kind of integration is needed to git.

The first project that will use the scripts is ki-flow. Eating your own dogfood is
a good way to get started and hopefully there will be some other projects with
different needs.

## Step 4 - Domain

http://ki-flow.org has been registered. It will contain these release notes for now.

--
23.12.2012, altitude 11km