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
      # Build config file based on .travis.yml
      #
      # More information at http://about.travis-ci.org/docs/user/build-configuration/
      #
      # extensions to the syntax:
      # * *build_version*, list of "build version" commands
      # * *import_component*, name of the component where the version is created
      class YmlBuildConfig
        attr_chain :ki_home, :require
        attr_chain :build_dir, :require
        attr_chain :metadata_file, -> {build_dir.path("ki-version.json")}
        attr_chain :config, -> {read_config}
        attr_chain :root_log, :require
        attr_chain :sh, -> {HashLogShell.new.chdir(build_dir.path).logger(root_log)}

        def handles_build_directory?(dir)
          dir.exist?("ki.yml")
        end

        def read_config
          require 'yaml'
          YAML.load_file(build_dir.path('ki.yml'))
        end

        def export_dependencies
          dependencies = Array(config.fetch("build_dependencies", nil))
          if(dependencies.size > 0)
            root_log.log("build_dependencies") do
              dependencies.each do |dep|
                root_log.log("foo") do |ver_log|
                  ver = VersionExporter.new.ki_home(ki_home).export(dep, build_dir.path)
                  ver_log.delete("name")
                  ver_log["version"]=ver.version_id
                end
              end
            end
          end
        end

        def execute_build
          if( env = config.fetch("env", nil))
            if ( global = env.fetch("global", nil))
              sh.env( map_env_list_to_map(global))
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

        def build_versions
          if (build_version_commands = config.fetch("build_version", nil))
            build_version_commands.each do |c|
              KiCommand.new.execute(%W(version-build --file #{metadata_file} #{c}))
            end
          end
        end

        def import_versions
          if (import_component = config.fetch("import_component", nil))
            VersionImporter.new.ki_home(ki_home).move_files(true).create_new_version(import_component).import(metadata_file, build_dir.path)
          end
        end

        def run_commands(command_id)
          sh_commands = Array(config.fetch(command_id, nil))
          if sh_commands.size > 0
            root_log.log(command_id) do |l|
              sh_commands.each do |c|
                run_command(c)
              end
            end
          end
        end

        def run_command(command)
          sh.spawn(command)
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
