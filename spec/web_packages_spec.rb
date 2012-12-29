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

def create_product_component
  @tester = Tester.new(example.metadata[:full_description])
  @tester.chdir(@source = @tester.tmpdir)
  @home = KiHome.new(@source)
  Tester.write_files(@source, "readme.txt" => "aa", "test.sh" => "bb")
  KiCommand.new.execute(%W(version-build --version-id my/component/23 -t foo test.sh --source-url http://test.repo/repo@21331 --source-tag-url http://test.repo/tags/23 --source-repotype git --source-author john))
  KiCommand.new.execute(%W(version-import -h #{@home.path}))
  FileUtils.rm("ki-version.json")
  KiCommand.new.execute(%W(version-build --version-id my/product/2 -t bar readme.txt -d my/component/23,name=comp,path=comp,internal) <<
                            "-o" << "cp comp/test.sh test.bat" << "-O" << "cp readme.txt README")
  KiCommand.new.execute(%W(version-import -h #{@home.path}))
end

describe PackagesWeb do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  def app
    PackagesWeb
  end

  it "should support /" do
    create_product_component
    RackCommand.web_ki_home=@home
    get '/components'
    [last_response.status, last_response.body].should eq [200, "my/component, my/product"]
  end
end