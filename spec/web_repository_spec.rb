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

describe RepositoryWeb do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    RackCommand.web_ctx.ki_home=nil
    @tester.after
  end

  def app
    RepositoryWeb
  end

  it "/components" do
    create_product_component
    RackCommand.web_ctx.ki_home=@home
    get '/components'
    last_response.status.should eq 200
    last_response.body.should =~/Components/
  end

  it "/json/components" do
    create_product_component
    RackCommand.web_ctx.ki_home=@home
    get '/json/components'
    [last_response.status, last_response.body, last_response.content_type].should eq [200,"[\"my/component\",\"my/product\"]","application/json;charset=utf-8"]
    get '/json/component/my/component/status_info'
    [last_response.status, last_response.body, last_response.content_type].should eq [200, "{}", "application/json;charset=utf-8"]
    get '/json/component/my/component/versions'
    [last_response.status, last_response.body, last_response.content_type].should eq [200, IO.read(@home.repository("local").component("my/component").versions.path), "application/json;charset=utf-8"]
    get '/json/version/my/component/23/metadata'
    [last_response.status, last_response.body, last_response.content_type].should eq [200, IO.read(@home.repository("local").version("my/component/23").metadata.path), "application/json;charset=utf-8"]
    get '/json/version/my/component/23/status'
    [last_response.status, last_response.body, last_response.content_type].should eq [200, "[[\"Smoke\",\"Green\"]]", "application/json;charset=utf-8"]
  end

  it "js-tests should pass" do
    create_product_component

    RackCommand.web_ctx.ki_home=@home
    port = RackCommand.find_free_tcp_port
    rack_command = RackCommand.new
    url = "http://localhost:#{port}/repository/components"
    @tester.cleaners << -> {rack_command.stop_server}
    chrome = ChromeDelegator.init
    @tester.catch_stdio do
      Thread.new do
        rack_command.execute(RackCommand.web_ctx, %W(-p #{port}))
      end
      RackCommand.wait_until_url_responds(url)
      chrome.navigate.to url
    end
    chrome.execute_script <<EOF
$("head").append('<link rel="stylesheet" href="/file/web/50efd9a1/Ki::RepositoryWeb:js-test/mocha.css" type="text/css" />');
$("head").append('<script type="text/javascript" src="/file/web/50efd9a1/Ki::RepositoryWeb:js-test/mocha.js"/>');
$("head").append('<script type="text/javascript" src="/file/web/50efd9a1/Ki::RepositoryWeb:js-test/chai.js"/>');
$("body").append('<div id="mocha"></div>');
mocha.setup('bdd');
chai.should();
$("head").append('<script type="text/javascript" src="/file/web/50efd9a1/Ki::RepositoryWeb:views/repository_js_test.coffee">');
mocha.run();
EOF
    if chrome.find_element(css: ".failures em").text != "0"
      puts chrome.find_element(css: "#mocha-report").text
    end
    [chrome.find_element(css: ".passes em").text, chrome.find_element(css: ".failures em").text].should eq ["3","0"]
  end
end