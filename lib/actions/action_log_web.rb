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
  class ActionLogWeb < Sinatra::Base
    include KiWebBase
    include CacheHeaders

    LogBaseDirectories = {}

    get '/json/logs/:base' do
      content_type :json
      IO.read(LogBaseDirectories.fetch(params["base"]).log_roots.path)
    end

    get '/json/logs/:base/*' do
      content_type :json
      log_dirs = LogBaseDirectories.fetch(params["base"]).log_roots.get(params["splat"].at(0)).log_dirs
      IO.read(log_dirs.path)
    end

    get '/json/log/:base/*/:id' do
      content_type :json
      action_log = LogBaseDirectories.fetch(params["base"]).log_roots.get(params["splat"].at(0)).log_dirs.get(params["id"]).action_log
      IO.read(action_log.path)
    end

    get '/files/:base/*/:id/file/:file' do
      action_log_dir = LogBaseDirectories.fetch(params["base"]).log_roots.get(params["splat"].at(0)).log_dirs.get(params["id"])
      if params["file"].include("../")
        halt 404
      end
      send_file action_log_dir.path(params["file"])
    end

    get '/' do
      erb :action_logs_page
    end

    get '/*' do
      erb :action_logs_page
    end
  end

  KiCommand.register("/web/logs", ActionLogWeb)
end