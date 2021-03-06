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

    LogBaseDirectories = {}

    get '/json/logs/:base' do
      content_type :json
      IO.read(LogBaseDirectories.fetch(params["base"]).log_roots.path)
    end

    get '/json/status/:base' do
      content_type :json
      IO.read(LogBaseDirectories.fetch(params["base"]).action_status.path)
    end

    def log_roots
      LogBaseDirectories.fetch(params["base"]).log_roots.reload
    end

    def log_dirs
      log_roots.get(params["splat"].at(0)).log_dirs.reload
    end

    def action_log_dir
      log_dirs.get(params["id"])
    end

    def action_log
      action_log_dir.action_log
    end

    get '/json/logs/:base/*' do
      content_type :json
      IO.read(log_dirs.path)
    end

    get '/json/log/:base/*/:id' do
      content_type :json
      IO.read(action_log.path)
    end

    get '/files/:base/*/:id/file/:file' do
      if params["file"].include?("../")
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