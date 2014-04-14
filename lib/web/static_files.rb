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
  module CacheHeaders
    def set_cache_headers
      if web_ctx.development
        cache_control :no_cache
      else
        expires 3*30*24*3600, :public, :must_revalidate
      end
    end
  end
  class StaticFileWeb < Sinatra::Base
    include KiWebBase

    get '/web/*/*' do
#      show_errors do
      set_cache_headers
      file = resolve_path(params[:splat].at(1))
      if file.end_with?(".scss")
        scss StaticFileWeb.read_file(file)
      elsif file.end_with?(".sass")
        sass StaticFileWeb.read_file(file)
      elsif file.end_with?(".coffee")
        coffee StaticFileWeb.read_file(file)
      elsif file.end_with?(".js")
        send_file(file, :type => "text/javascript")
      elsif file.end_with?(".css")
        send_file(file, :type => "text/css")
#      end
      end
    end

    def StaticFileWeb.read_file(file)
      IO.read(file)
    end

    def resolve_path(requested_file)
      *version_or_class_arr, file = requested_file.split(":")
      if file.include?("..")
        raise "File '#{file}' can't include '..'"
      end

      clazz = Object.const_get_full(version_or_class_arr.join(":"))

      # Rack's settings.root gives the root directory location
      File.join(clazz.settings.root, file)
    end
  end

  KiCommand.register("/web/file", StaticFileWeb)
end