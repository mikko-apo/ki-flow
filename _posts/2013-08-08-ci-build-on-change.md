---
layout: default
title: ci-build-on-change
author: Mikko Apo
---

# CI building works, kind of

After a week of coding, a simple CI implementation is ready. It's possible to execute builds,
build packages and import them to the repository automatically. The build process can be
executed only after there is a change in the version control (only git support at the moment).
There is also support for creating product builds, that combine multiple components together.

This post describes how to get the system working.
There are still quite a few manual steps needed to get things rolling,
but hopefully this will improve by time.

note: there is no daemon support yet, so builds have to be triggered manually :)

Huge thanks to [Reaktor](http://reaktor.fi/), Janni and Miku for supporting this project.

## Setup ki-repo gem

    mkdir ~/src
    cd ~/src
    git clone git@github.com:mikko-apo/ki-repo.git
    cd ki-repo
    bundle install
    rake build
    gem install --local pkg/ki-repo-*.gem

ki command line utility is now available

## Take ki-flow in to use

    cd ~/src
    git clone git@github.com:mikko-apo/ki-flow.git
    ki pref require + ~/src/ki-flow/lib/ki_flow.rb

Now the ki command automatically loads ki-flow files and ki-flow's command line utilities and web pages are available

## Start ki-flow web page

    ki web

Open browser to [http://localhost:8290/repository/](http://localhost:8290/repository/)

## Example build tool: build/sbt

Next we'll create a simple tool that builds a release by copying a file. The file is packaged
and imported in to ki repository.

    mkdir -p ~/src/ki_sbt/build
    cd ~/src/ki_sbt/build
    echo '#!/usr/bin/env bash' >> sbt.sh
    echo 'cp info.txt result.txt' >> sbt.sh
    chmod u+x sbt.sh
    cd ..
    ki version-build build
    ki version-import --move -c ki/sbt

Note: you can now delete ~/src/ki_sbt, it's files are stored in your local ki repository.

ki_sbt/1 should be visible in the repository page if you refresh the browser.

## Demo project

We'll create a demo project, which contains a ki.yml build configuration.
ki.yml instructs ki ci-build on how to build the package.

    mkdir -p ~/src/ki_demo
    cd ~/src/ki_demo
    git init
    echo DEMO >> info.txt

Next create ki.yml file with following contents

    build_dependencies: ki/sbt
    script: build/sbt.sh
    build_version:
      - result.txt
    import_component: demo/result

* build_dependencies are exported to build directory
* commands defined by script are executed to produce the package
* build_version describes what should be packaged
* import_component defines the root name for the package. ki adds next available version number to produce the full version string.

Commit these files to git

    git add *.*
    git commit -m 'initial commit'

## Configure CI builds

CI builds are configured to a separate directory.

    mkdir -p ~/src/ki_ci_builds
    cd ~/src/ki_ci_builds

Create a file called ~/src/ki_ci_builds/ki-builds.json with following contents

    {
        "builds": [
            {"remote_url": "../ki_demo:master"}
        ]
    }

The file allows "ki ci-build-on-change" to look for ki_demo git repository.

Now run the first build for ki_demo

    ki ci-build-on-change

Refresh the browser, there should be a new component called "demo/result" and it should have one version available.

If you run "ki ci-build-on-change" again, no new versions are created because there isn't any changes.

## Modifying demo project produces new build

Modify demo

    cd ~/src/ki_demo
    echo FINISHED >> info.txt
    git add *.*
    git commit -m 'second commit'

Execute another build

    cd ~/src/ki_ci_builds
    ki ci-build-on-change

If you refresh the browser, there should be two versions for "demo/result".

If you browse the ~/src/ki_ci_builds directory, you'll see that
* ki-builds.json has been updated, it now contains local_path and last_revision
* builds/ki_demomaster contains a clone of the original repository

## Creating a product build

Product builds define dependencies to other components. If there is a new version available from a dependency
product build can build new product version.

    cd ~/src/ki_ci_builds

Modify ~/src/ki_ci_builds/ki-builds.json with following contents

    {
        "builds": [
            {
                ...
            }
        ],
        "products": [
            {
                "component": "ki/product",
                "dependencies": [
                    { "name": "sbt", "source": "ki/sbt/1", "path": "utils"},
                    { "name": "demo", "source": "demo/result"}
                ]
            }
        ]
    }

Run

    ki ci-build-on-change

Now there should be a product available in the browser that depends on two packages.

## Clean things up

To clean thing from your src directory, remove ~/src/ki_demo and ~/src/ki_ci_builds

    rm -rf ~/src/ki_demo ~/src/ki_ci_builds

All ki repository files are located under ~/ki, you can safely delete that directory if you don't use ki to store packages.

    rm -rf ~/ki

Uninstall ki gem

    gem uninstall ki

# What next?

The CI implementation is quite immature. Following features are next on the backlog:

* Logs for builds
* Test result handling
* Product build for collection versions from different components
* Daemon process that automatically triggers builds

--
08.08.2013 @ Olari