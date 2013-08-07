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
    module BuildConfig
      class YmlBuildConfig
        attr_chain :ki_home, :require
        attr_chain :build_dir, :require
        attr_chain :config, -> {read_config}
        attr_chain :shell, -> {HashLogShell.new.chdir(build_dir.path)}

        def handles_build_directory?(dir)
          dir.exists?("ki.yml")
        end

        def read_config
          require 'yaml'
          YAML.load_file(build_dir.path('ki.yml'))
        end

        def export_dependencies
          Array(config.fetch("build_dependencies", nil)).each do |dep|
            VersionExporter.new.ki_home(ki_home).export(dep, build_dir.path)
          end
        end

        def execute_build
          if( env = config.fetch("env", nil))
            if ( global = env.fetch("global", nil))
              shell.env( map_env_list_to_map(global))
            end
          end
          ["before_install", "install", "before_script"].each do |c|
            run_commands(c)
          end
          ok = run_commands("script")
          if(ok)
            run_commands("after_success")
          else
            run_commands("after_failure")
          end
          run_commands("after_script")
        end

        def build_versions_and_import
          if (build_version_commands = config.fetch("build_version", nil))
            build_version_commands.each do |c|
              KiCommand.new.execute(%W(version-build --file #{build_dir.path("ki-version.json")} #{c}))
            end
          end
          if (import_component = config.fetch("import_component", nil))
            KiCommand.new.execute(%W(version-import -h #{ki_home.path} -i #{build_dir.path} --move -c #{import_component}))
          end
        end

        def run_commands(command_id)
          Array(config.fetch(command_id, nil)).each do |c|
            run_command(c)
          end
        end

        def run_command(command)
          shell.spawn(command)
        end

        def map_env_list_to_map(list)
          key_val_list = list.map do |s|
            arr = s.split("=")
            key = arr.delete_at(0)
            val = arr.join("=")
            [key.strip, val.strip]
          end
          Hash[*key_val_list.flatten]
        end
      end

      KiCommand.register("/ci/build/config/ki.yml", YmlBuildConfig)
    end
  end

end
