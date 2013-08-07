# Test web site manually

    bin/ki web --require ../ki-flow/lib/ki_flow.rb --development

# Important Ruby classes

## Command line utilities - /commands/

* ci-build - {Ki::Ci::CiBuildCommand}

## Build Config Extensions - /ci/build/config/

* ki.yml - {Ki::Ci::BuildConfig::YmlBuildConfig}

## Web app - /web/

* repository - {Ki::RepositoryWeb} - Packages and versions
* file - {Ki::StaticFileWeb} - Static resources, on the fly conversion