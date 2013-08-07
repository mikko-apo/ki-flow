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

describe Ki::Ci::CiBuildCommand do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should run full build" do
    @tester.chdir(source = @tester.tmpdir)
    home = KiHome.new(@tester.tmpdir)

    # create ki/ant/1
    Tester.write_files(
        source,
        "ant.sh" => "#!/usr/bin/env bash
echo ANT >> result.txt"
    )
    system("chmod u+x #{source}/ant.sh")
    KiCommand.new.execute(%W(version-build ant.sh))
    KiCommand.new.execute(%W(version-import -h #{home.path} --move -c ki/ant))

    # create ki/sbt/1
    Tester.write_files(
        source,
        "sbt.sh" => "#!/usr/bin/env bash
echo SBT $TIMEOUT >> result.txt
cat info.txt >> result.txt"
    )
    system("chmod u+x #{source}/sbt.sh")
    KiCommand.new.execute(%W(version-build sbt.sh))
    KiCommand.new.execute(%W(version-import -h #{home.path} --move -c ki/sbt))

    build_config = <<EOF
build_dependencies:
  - ki/ant
  - ki/sbt
before_install: echo Before install >> result.txt
install: ./ant.sh
after_install:
  - echo After install 1 >> result.txt
  - echo After install 2 >> result.txt
before_script:
  - echo Before script 1 >> result.txt
  - echo Before script 2 >> result.txt
script: ./sbt.sh
after_script: echo After script >> result.txt
build_version:
  - result.txt
import_component: test/result
env:
  global:
    - TIMEOUT=1000
EOF

    build_dir = @tester.tmpdir

    Tester.write_files(build_dir,
                       "info.txt" => "INFO
",
                       "ki.yml" => build_config
    )

    KiCommand.new.execute(%W(ci-build -d #{build_dir} -h #{home.path}))

    v = home.version("test/result")
    IO.read(v.binaries.path("result.txt")).should eq("Before install
ANT
Before script 1
Before script 2
SBT 1000
INFO
After script
")
  end

end