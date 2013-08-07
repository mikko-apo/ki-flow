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

describe Ki::Ci::BuildConfig::YmlBuildConfig do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should execute build" do
    @tester.chdir(@source = @tester.tmpdir)
    @home = KiHome.new(@source)
    file = <<EOF
before_install: some_command
install: ant install-deps
after_install:
  - after_command_1
  - after_command_2

before_script:
  - before_command_1
  - before_command_2
script: ./run_build.sh
after_script: after_script.sh

env:
  global:
    - TIMEOUT=1000
EOF
    Tester.write_files(@source, "ki.yml" => file)
    builder = Ki::Ci::BuildConfig::YmlBuildConfig.new
    h = {
        "before_install"=>"some_command",
        "install"=>"ant install-deps",
        "after_install"=>["after_command_1", "after_command_2"],
        "before_script"=>["before_command_1", "before_command_2"],
        "script"=>"./run_build.sh",
        "after_script"=>"after_script.sh",
        "env"=>{"global"=>["TIMEOUT=1000"]}
    }
    builder.build_dir = @home
    builder.read_config().should eq h
  end

end
