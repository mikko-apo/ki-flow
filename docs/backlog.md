# @title ki-flow: Backlog

* renderElements - dom element templates, fix missing elements for script templates
* assertElements - functions
* optimize static file serving, headers and compress static files with gz and store to cache
* pushstate - urls. https://github.com/olivernn/davis.js
* packages web ui - version status

# Next release

* packages web ui
** show
** browse
* cmd: "ki ci-scan https://github.com/mikko-apo/ki-flow/"
** download repository
** check for buildable projects
** configure found builds (source, command, collectable artifacts, version id)
* product build
** web-ui: configure dependencies
** daemon: check for changes
* daemon
** should load scripts and execute them in separate processes
* action logs
* version license summary

# Future releases

* compare versions: files, dependencies, source diff
* authorization
** users and groups
* env resource pools
* hierarchic properties
* js-testing: xunit output