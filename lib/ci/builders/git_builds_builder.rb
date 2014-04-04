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

    class VCBuilder
      attr_chain :ki_home, :require

      def check(builds, exceptions)
        builds.each do |build_config|
          remote_url = build_config.fetch("remote_url")
          exceptions.catch(remote_url) do
            vc = KiCommand::KiExtensions.find("/ci/version_control/" + vc_name).new
            vc.sh(HashLogShell.new.root_log(DummyHashLog.new))
            update_and_execute_if_changes(build_config, vc, remote_url)
          end
        end
      end

      def update_and_execute_if_changes(build_config, vc, remote_url)
        remote_revision = vc.get_revision(remote_url)
        local_revision = build_config["last_revision"]
        if (remote_revision != local_revision)
          local_path = local_path(build_config, remote_url)
          vc.update_or_clone_repository_to_local_path(remote_url, local_path)
          build_config["last_revision"] = remote_revision
          execute_build(local_path)
        end
      end

      def execute_build(local_path)
        CiBuild.new.ki_home(ki_home).build(local_path.path)
      end

      def local_path(build_config, remote_url)
        local_path_str = build_config["local_path"]
        if (local_path_str.nil?)
          build_config["local_path"] = local_path_str = "builds/" + escape_url_to_path(remote_url)
        end
        local_path = DirectoryBase.new(local_path_str)
        local_path.mkdir
        local_path
      end

      def escape_url_to_path(str)
        str.gsub(/[\/:\.]/,"")
      end
    end

    class GitBuildsBuilder < VCBuilder
      attr_chain :vc_name, -> {"git"}
    end

    KiCommand.register("/ci/builders/git", GitBuildsBuilder)
  end
end
