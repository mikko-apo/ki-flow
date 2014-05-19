# @title ki-flow: Backlog

# Action logs
- fix search
- fix hash display on load
- cmd output log should show timing and errors with colors
- expand all
- fix left align

# CI
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

* optimize static file serving, headers and compress static files with gz and store to cache
* assertElements: functions
* assertElement: for list data collect all values in one

# Future releases

* compare versions: files, dependencies, source diff
* authorization
** users and groups
* env resource pools
* hierarchic properties
* js-testing: xunit output
* version license metadata

# Structure
* Component - Version
* Action List/History - Action
* Environment - Environment version
* Action
** Versions
** Environment version
** Action Parameters
* Resource

# Views
* Action
** overview
** stats
** test results
** version dependencies
* Component history
* Environment
*