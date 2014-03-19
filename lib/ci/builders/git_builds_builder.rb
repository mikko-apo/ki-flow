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
    class GitBuildsBuilder
      attr_chain :ki_home, :require

      def check(builds, exceptions)
        builds.each do |build_config|
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

    KiCommand.register("/ci/builders/builds", GitBuildsBuilder)
  end
end
