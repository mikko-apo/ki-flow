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
      attr_chain :repository_url, :require, :accessor => CachedData
    end

    # Runs full CI build process
    class CiBuildCommand
      attr_chain :dir, -> { Dir.pwd }
      attr_chain :shell_command, :require

      def execute(ctx, args)
        opts.parse(args)
        build_config = load_config(ctx, dir)
        build_config.export_dependencies
        build_config.execute_build
#        build_config.check_test_results
        build_config.build_versions_and_import
#        build_config.store_test_results
#        build_config.store_logs
      end

      def load_config(ctx, dir)
        dirObject = DirectoryBase.new(dir)
        configs = KiCommand::KiExtensions.find("/ci/build/config")
        configs.services.each do |c|
          config = c.new
          config.ki_home=ctx.ki_home
          if(config.handles_build_directory?(dirObject))
            config.build_dir = dirObject
            return config
          end
        end
        raise "Could not resolve build config for directory '#{dir}'! Tried with different build configs(#{configs.size}): '#{configs.service_names.join("', '")}'"
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
