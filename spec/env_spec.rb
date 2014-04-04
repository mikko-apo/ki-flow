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

require_relative 'spec_helper'

describe Ki::Env do
  before do
    @env = Ki::Env.new(nil)
    @a = {
        "names" => ["a"],
        "tags" => ["t1","t2","t3"]
    }
    @b = {
        "names" => ["b"],
        "tags" => ["t1","t3"],
        "max_reservations" => 1
    }
    @env.cached_data([@a,@b])
  end

  it "should handle select" do
    @env.select{true}.should eq([@a,@b])
    @env.select{|e| e.tagged?("t1")}.should eq([@a,@b])
    @env.select{|e| e.tagged?("t2")}.should eq([@a])
    @env.select{|e| e.tagged?("t1","t3")}.should eq([@a,@b])
  end

  it "should handle reservations" do
    a , b = @env.select{true}
    a.names.should eq ["a"]
    a.free?.should eq(true)
    a.reservations.should eq([])
    a.reserve(1)
    a.reservations.should eq([1])
    b.free?.should eq(true)
    b.reservations.should eq([])
    b.reserve(2)
    b.reservations.should eq([2])
    b.free?.should eq(false)
    lambda { b.reserve(3) }.should raise_error("Can't make a reserve '[\"b\"]' with '3': max_reservations 1 -> [2]")
  end
end