# encoding: UTF-8

# Copyright 2012 Mikko Apo
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

describe StaticFileWeb do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  def app
    StaticFileWeb
  end

  it "should have helper methods" do
    StaticFileWeb.read_file(__FILE__)
  end

  it "should support serving static files and automatic conversions" do
    create_product_component
    RackCommand.web_ctx.ki_home=@home
    root = File.expand_path(File.join(__FILE__, "../../lib/web"))
    StaticFileWeb.expects(:read_file).with(File.join(root, "foo.scss")).returns "$margin: 16px;\n.border {\nmargin: $margin / 2;\n}"
    get '/web/Ki::PackagesWeb:foo.scss'
    css = ".border {\n  margin: 8px; }\n"
    css_headers = {"Content-Type" => "text/css;charset=utf-8", "Content-Length" => "27"}
    [last_response.status, last_response.body, last_response.header].should eq [200, css, css_headers]

    StaticFileWeb.expects(:read_file).with(File.join(root,"foo.sass")).returns "$margin: 16px\n.border\n  margin: $margin / 2\n"
    get '/web/Ki::PackagesWeb:foo.sass'
    [last_response.status, last_response.body, last_response.header].should eq [200, css, css_headers]

    StaticFileWeb.expects(:read_file).with(File.join(root,"foo.coffee")).returns "square = (x) -> x * x"
    get '/web/Ki::PackagesWeb:foo.coffee'
    coffee = "(function() {\n  var square;\n\n  square = function(x) {\n    return x * x;\n  };\n\n}).call(this);\n"
    coffee_headers = {"Content-Type" => "application/javascript;charset=utf-8", "Content-Length" => "93"}
    [last_response.status, last_response.body, last_response.header].should eq [200, coffee, coffee_headers]
  end

  it "should error on bad paths" do
    get '/web/Ki::PackagesWeb:../foo.scss'
    last_response.status.should eq 500
    last_response.body.should =~/File &#x27;..&#x2F;foo.scss&#x27; can&#x27;t include &#x27;..&#x27;/
  end
end