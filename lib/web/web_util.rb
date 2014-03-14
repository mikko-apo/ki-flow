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
  class MonitorApp < Sinatra::Base
    def initialize(id, block = nil)
      super()
      @id = id
      @block = block
    end

    get '/id' do
      @id
    end

    get '/id/:id' do
      if params[:id] != @id
        halt 400, "Running process with id '#{@id}', not /alive/#{params[:id]}"
      end
      @id
    end

    get '/alive' do
      if @block
        @block.call
      else
        halt 400, "/alive not supported!"
      end
    end
  end
end
