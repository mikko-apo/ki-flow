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

  module EnvEntry
    attr_chain :names, -> { Array.new }, :accessor => AttrChain::HashAccess

    attr_chain :reservations, -> { Array.new }, :accessor => AttrChain::HashAccess
    attr_chain :max_reservations, -> { nil }, :accessor => AttrChain::HashAccess

    def free?
      max_reservations.nil? || reservations.size < max_reservations
    end

    def reserve(key)
      if !free?
        raise "Can't make a reserve '#{names}' with '#{key}': max_reservations #{max_reservations} -> #{reservations}"
      end
      reservations << key
    end

    def free(key)
      reservations.delete(key)
    end

    attr_chain :tags, -> { Array.new }, :accessor => AttrChain::HashAccess

    def tagged?(*tag_list)
      tag_list.each do |tag|
        if !tags.include?(tag)
          return false
        end
      end
      true
    end
  end

  class Env < KiJSONListFile
    include MonitorMixin
    attr_chain :item_type, -> { EnvEntry }

    def create_list_item(obj)
      obj.extend(item_type)
    end

  end
end