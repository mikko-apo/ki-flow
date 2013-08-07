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
    class CiBuildConfigFile < KiJSONHashFile
      attr_chain :builds, :require, -> { Array.new }, :accessor => CachedData
    end

    class CiBuildOnChange
      attr_chain :ki_home, :require
      def build_on_change
        config = CiBuildConfigFile.new("ki-builds.json")
        git = VersionControl::Git.new
        exceptions = ExceptionCatcher.new
        config.builds.each do |build_config|
          remote_url = build_config.fetch("remote_url")
          exceptions.catch(remote_url) do
            remote_revision = git.get_revision(remote_url)
            local_revision = build_config["last_revision"]
            if (remote_revision != local_revision)
              local_path = update_or_clone_repository_to_local_path(build_config, git, remote_url)
              build_config["last_revision"] = remote_revision
              CiBuild.new.ki_home(ki_home).build(local_path.path)
            end
          end
        end
        config.save
        exceptions.check
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

      def build(dir)
        build_config = load_config(dir)
        build_config.export_dependencies
        build_config.execute_build
#        build_config.check_test_results
        build_config.build_versions
        build_config.import_versions
#        build_config.store_test_results
#        build_config.store_logs
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
