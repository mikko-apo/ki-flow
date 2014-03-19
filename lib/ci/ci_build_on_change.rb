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
        config.cached_data.keys.each do |key|
          builder = KiCommand::KiExtensions.find("/ci/builders/" + key)
          if builder
            builder.new.ki_home(ki_home).check(config.cached_data[key], exceptions)
          else
            puts "Not supported builder: #{key}"
          end
        end
        # check_builds(config, exceptions)
        # check_products(config, exceptions)
        config.save
        exceptions.check
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
  end
end
