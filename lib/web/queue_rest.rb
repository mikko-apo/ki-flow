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
  class QueueRest < Sinatra::Base
    include KiWebBase
    Files = {}

    def queue_dir
      ki_home.mkdir("queues")
    end

    def get_queue(name)
      if file = Files[name]
        file
      else
        KiJSONListFile.new(name + ".json").parent(queue_dir)
      end
    end

    get '/:name' do
      content_type :json
      IO.read(get_queue(params[:name]).path)
    end

    post '/:name/*' do
      get_queue(params[:name]).add_item(*params[:splat])
    end

    delete '/:name' do
      get_queue(params[:name]).pop
    end

  end
  KiCommand.register("/web/queue", QueueRest)
end