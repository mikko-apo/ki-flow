# encoding: UTF-8

# Copyright 2012-2013 Mikko Apo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Ki

  module Ci
    #    {
    #      "builds": [
    #        {
    #          "remote_url": "../ki_demo:master",
    #          "local_path": "builds/ki_demomaster",
    #          "last_revision": "aaa233121"
    #        }
    #      ],
    #      "products": [
    #        {
    #          "component": "ki/product",
    #          "dependencies": [
    #            {
    #              "name": "a",
    #              "source": "ki/demo",
    #              "last_version": "ki/demo/123"
    #            }
    #          ]
    #        }
    #      ]
    #    }
    class CiBuildConfigFile < KiJSONHashFile
      attr_chain :builds, :require, -> { Array.new }, :accessor => CachedData
      attr_chain :products, :require, -> { Array.new }, :accessor => CachedData
    end

    class CiBuildOnChange
      attr_chain :ki_home, :require
      def build_on_change
        config = CiBuildConfigFile.new("ki-builds.json")
        exceptions = ExceptionCatcher.new
        check_builds(config, exceptions)
        check_products(config, exceptions)
        config.save
        exceptions.check
      end

      def check_builds(config, exceptions)
        config.builds.each do |build_config|
          remote_url = build_config.fetch("remote_url")
          exceptions.catch(remote_url) do
            git = VersionControl::Git.new
            git.sh(HashLogShell.new.root_log(DummyHashLog.new))
            remote_revision = git.get_revision(remote_url)
            local_revision = build_config["last_revision"]
            if (remote_revision != local_revision)
              local_path = update_or_clone_repository_to_local_path(build_config, git, remote_url)
              build_config["last_revision"] = remote_revision
              CiBuild.new.ki_home(ki_home).build(local_path.path)
            end
          end
        end
      end

      def check_products(config, exceptions)
        config.products.each do |product_config|
          component_name = product_config["component"]
          exceptions.catch(component_name) do
            build_product(product_config, component_name)
          end
        end
      end

      def build_product(product_config, component_name)
        metadata = VersionMetadataFile.new("ki-version.json")
        new_deps = []
        version_lookup = {}
        # collect dependencies from config and generate new dependencies list
        old_deps = product_config.fetch("dependencies").map do |dep|
          tmp_dep = dep.dup
          tmp_dep["version_id"] = tmp_dep.delete("last_version")
          tmp_dep.delete("source")
          new_dep = tmp_dep.dup
          new_version_id = ki_home.version(dep["source"]).version_id
          version_lookup[dep["name"]] = new_version_id
          new_dep["version_id"] = new_version_id
          new_deps << new_dep
          tmp_dep
        end
        # if deps config has changes, import and create new version
        if (old_deps != new_deps)
          product_config.fetch("dependencies").each do |dep|
            dep["last_version"] = version_lookup[dep["name"]]
          end
          metadata.dependencies.concat(new_deps)
          metadata.save
          KiCommand.new.execute(%W(version-import -h #{ki_home.path} -f #{metadata.path} --move -c #{component_name}))
        end
      end

      def update_or_clone_repository_to_local_path(build_config, git, remote_url)
        local_path_str = build_config["local_path"]
        if (local_path_str.nil?)
          build_config["local_path"] = local_path_str = "builds/" + escape_url_to_path(remote_url)
        end
        local_path = DirectoryBase.new(local_path_str)
        local_path.mkdir
        if (local_path.empty?)
          git.download_remote_repo_to_local(remote_url, local_path)
        else
          git.reset_local_repo(local_path)
          git.update_local_repo(local_path)
        end
        local_path
      end

      def escape_url_to_path(str)
        str.gsub(/[\/:\.]/,"")
      end
    end

    class CiBuildOnChangeCommand
      attr_chain :shell_command, :require

      def execute(ctx, args)
        CiBuildOnChange.new.ki_home(ctx.ki_home).build_on_change()
      end

      def summary
        "Checks if builds need to be run"
      end

      def help
        <<EOF
"#{shell_command}" #{summary}.
EOF
      end
    end

    KiCommand.register_cmd("ci-build-on-change", CiBuildOnChangeCommand)

    class CiBuild
      attr_chain :ki_home, :require
      include HashLog

      def build(dir)
        root_log = nil
        imported_version = nil
        begin
          log("Build") do |log|
            root_log = log
            build_config = load_config(dir)
            build_config.root_log(self)
            build_config.export_dependencies
            build_config.execute_build
    #        build_config.check_test_results
            build_config.build_versions
            imported_version = build_config.import_versions
    #        build_config.store_test_results
    #        build_config.store_logs
          end
        ensure
          if imported_version
            root_log["version"]=imported_version.version_id
            root_log["ki-version"]=KiHome.ki_version
            store_logs(imported_version, root_log)
          end
        end
      end

      def load_config(dir)
        dirObject = DirectoryBase.new(dir)
        configs = KiCommand::KiExtensions.find("/ci/build/config")
        configs.services.each do |c|
          config = c.new
          config.ki_home=ki_home
          if (config.handles_build_directory?(dirObject))
            config.build_dir = dirObject
            return config
          end
        end
        raise "Could not resolve build config for directory '#{dir}'! Tried with different build configs(#{configs.size}): '#{configs.service_names.join("', '")}'"
      end

      def store_logs(imported_version, root_logs)
        version = VersionImporter.create_version_dir(ki_home, "build", imported_version.component.component_id, imported_version.name)
        version.build_logs.save(root_logs)
      end
    end

    # Runs full CI build process
    class CiBuildCommand
      attr_chain :dir, -> { Dir.pwd }
      attr_chain :shell_command, :require

      def execute(ctx, args)
        opts.parse(args)
        CiBuild.new.ki_home(ctx.ki_home).build(dir)
      end

      def opts
        OptionParser.new do |opts|
          opts.banner = ""
          opts.on("-d", "--directory INPUT-DIR", "Build directory") do |v|
            dir(v)
          end
          opts.on("-l", "--logs LOG-DIR", "Root directory for logs") do |v|
            log_root(v)
          end
        end
      end

      def summary
        "Runs a CI build cycle once"
      end

      def help
        <<EOF
"#{shell_command}" #{summary}.

1. load config
2. export build deps
3. execute build
4. check test results
5. build version(s) and import
6. store test results
7. store logs

### Examples

### Parameters
#{opts}
EOF
      end
    end

    KiCommand.register_cmd("ci-build", CiBuildCommand)
  end
end
