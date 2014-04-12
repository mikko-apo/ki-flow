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
  class ActionLogRootList < KiJSONListFile
    def create_list_item(obj)
      ActionLogRoot.new(obj).parent(parent)
    end
  end

  class ActionBaseDirectory < DirectoryBase
    attr_chain :log_roots, -> {ActionLogRootList.new("log_roots.json").parent(mkdir)}
    def add_log_root(name)
      log_roots.add_item(name)
    end
  end

  class ActionLogDirList < KiJSONListFile
    def create_list_item(obj)
      ActionLogDir.new(obj).parent(parent)
    end
  end

  class ActionLogRoot < DirectoryBase
    attr_chain :log_dirs, -> {ActionLogDirList.new("log_dirs.json").parent(mkdir)}
    def add_log_dir(name)
      log_dirs.add_item(name)
    end

    def new_log_dir
      last = log_dirs.cached_data.last
      if last.nil?
        add_log_dir("1")
      else
        add_log_dir( "#{last.to_i + 1}" )
      end
    end
  end

  class ActionLogDir < DirectoryBase
    attr_chain :action_log, -> {KiJSONHashFile.new("action_log.json").parent(mkdir)}
  end
end