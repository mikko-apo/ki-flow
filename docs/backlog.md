# @title ki-flow: Backlog

# CI
* build action logs
* logs should be collected
* test results should be parsed and collected
* cmd: "ki ci-scan https://github.com/mikko-apo/ki-flow/"
** download repository
** check for buildable projects
** configure found builds (source, command, collectable artifacts, version id)
* product build
** web-ui: configure dependencies
** daemon: check for changes
* daemon
** should load scripts and execute them in separate processes

# Web

* packages web ui
** show
** browse
* renderElements - fix for multi-dest, now uses hardcoded element from dest[0]
* optimize static file serving, headers and compress static files with gz and store to cache
* assertElements: functions
* assertElement: for list data collect all values in one
* pushstate improvements - https://github.com/olivernn/davis.js

# Future releases

* compare versions: files, dependencies, source diff
* authorization
** users and groups
* env resource pools
* hierarchic properties
* js-testing: xunit output
* version license metadata