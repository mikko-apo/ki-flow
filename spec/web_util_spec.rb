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

require 'spec_helper'

describe Ki::MonitorApp do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should return rack ID" do
    port = WebUtil.find_free_tcp_port
    rack = DefaultRackHandler.new
    @tester.cleaners << -> {rack.stop}
    @tester.catch_stdio do
      Thread.new do
        rack.run( Ki::MonitorApp.new("123"), :Port => port)
      end
      WebUtil.wait_until_url_responds("http://localhost:#{port}/id") do |response|
        [response.code, response.body].should eq ["200", "123"]
      end
      WebUtil.wait_until_url_responds("http://localhost:#{port}/id/123") do |response|
        [response.code, response.body].should eq ["200", "123"]
      end
      WebUtil.wait_until_url_responds("http://localhost:#{port}/id/124") do |response|
        [response.code, response.body].should eq ["400", "Running process with id '123', not /alive/124"]
      end
      WebUtil.wait_until_url_responds("http://localhost:#{port}/alive") do |response|
        [response.code, response.body].should eq ["400", "/alive not supported!"]
      end
    end.stderr.join("\n").should =~/#{port}/
  end

  it "should call block" do
    port = WebUtil.find_free_tcp_port
    rack = DefaultRackHandler.new
    @tester.cleaners << -> {rack.stop}
    @called = "not"
    app = Ki::MonitorApp.new("123", lambda {@called = "true"})
    Thread.new do
      rack.run( app, :Port => port)
    end
    @tester.catch_stdio do
      WebUtil.wait_until_url_responds("http://localhost:#{port}/id") do |response|
        [response.code, response.body].should eq ["200", "123", ]
      end
      @called.should eq "not"
      WebUtil.wait_until_url_responds("http://localhost:#{port}/alive") do |response|
        [response.code, response.body, @called].should eq ["200", "true", "true"]
      end
    end.stderr.join("\n").should =~/#{port}/
  end

end

