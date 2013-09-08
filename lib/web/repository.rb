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
  class RepositoryWeb < Sinatra::Base
    include KiWebBase
    get '/json/components' do
      content_type :json
      ki_home.finder.components.keys.to_json
    end

    get '/json/component/*/status_info' do
      content_type :json
      ki_home.finder.component(params[:splat].first).status_info.to_json
    end

    get '/json/component/*/versions' do
      content_type :json
      IO.read(ki_home.finder.component(params[:splat].first).versions.path)
    end

    get '/json/version/*/metadata' do
      content_type :json
      IO.read(ki_home.finder.version(params[:splat].first).metadata.path)
    end

    get '/json/version/*/status' do
      content_type :json
      ki_home.finder.version(params[:splat].first).statuses.to_json
    end

    get '/routes' do
      routes = []
      settings.routes.each_pair do |method, actions|
        actions.each do |a_regexp, splat_arr, empty_arr, proc|
          routes << [a_regexp.source[1..-2], method, splat_arr, empty_arr, proc]
        end
      end
      output = <<EOF
<html>
<body>
<table>
<tr><th>Path</th><th>Method</th><th>Params</th></tr>
<% routes.each do |action, method, splat_arr, empty_arr, proc| %>
  <tr><td><%=action%></td><td><%=method%></td><td><%=splat_arr.join(" ")%></td></tr>
<% end %>
</table>
</body>
</html>
EOF
      erb output, :locals => {routes: routes}
    end

    get '/' do
      erb :repository_page
    end

    get '/*' do
      erb :repository_page
    end
  end

  KiCommand.register("/web/repository", RepositoryWeb)
end