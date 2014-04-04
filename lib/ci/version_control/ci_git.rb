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
    module VersionControl
      class GitPath
        attr_chain :url
        attr_chain :branch
      end
      class Git
        attr_chain :sh, :require
        def get_revision(url)
          path = unpack_url(url)
          result = sh.spawn("git ls-remote --heads #{path.url} #{path.branch}")
          result.out.split(/\s/)[0]
        end

        def reset_local_repo(dir)
          sh.spawn("git clean --force", chdir: dir.path)
          sh.spawn("git reset --hard", chdir: dir.path)
        end

        def update_local_repo(dir)
          sh.spawn("git pull", chdir: dir.path)
        end

        def download_remote_repo_to_local(url, dir)
          path = unpack_url(url)
          sh.spawn("git clone --branch #{path.branch} #{path.url} #{dir.path}")
        end

        def unpack_url(s)
          arr = s.split(":")
          GitPath.new.branch(arr.delete_at(-1)).url(arr.join(":"))
        end

        def update_or_clone_repository_to_local_path(remote_url, local_path)
          if (local_path.empty?)
            download_remote_repo_to_local(remote_url, local_path)
          else
            reset_local_repo(local_path)
            update_local_repo(local_path)
          end
        end

      end
      KiCommand.register("/ci/version_control/git", Git)
    end
  end
end
