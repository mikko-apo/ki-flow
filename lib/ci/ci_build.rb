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
