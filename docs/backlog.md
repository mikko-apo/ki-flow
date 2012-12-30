# @title ki-flow: Backlog

* optimize static file serving, headers and compress static files with gz and store to cache
* packages web ui
** show
** browse
** compare versions: files, dependencies, diff
* cmd: "ki ci-scan https://github.com/mikko-apo/ki-flow/"
** download repository
** check for buildable projects
** configure found builds (source, command, collectable artifacts, version id)
* product build
** web-ui: configure dependencies
** daemon: check for changes
* daemon
** should load scripts and execute them in separate processes
* env resource pools
* hierarchic properties
* action logs
* authorization
** users and groups
