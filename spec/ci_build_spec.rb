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

  def create_ki_ant(home, source)
    Tester.write_files(
        source,
        "ant.sh" => "#!/usr/bin/env bash
echo ANT >> result.txt"
    )
    system("chmod u+x #{source}/ant.sh")
    KiCommand.new.execute(%W(version-build ant.sh))
    KiCommand.new.execute(%W(version-import -h #{home.path} --move -c ki/ant))
  end

  def create_ki_sbt(home, source)
    Tester.write_files(
        source,
        "sbt.sh" => "#!/usr/bin/env bash
echo SBT $TIMEOUT >> result.txt
cat info.txt >> result.txt"
    )
    system("chmod u+x #{source}/sbt.sh")
    KiCommand.new.execute(%W(version-build sbt.sh))
    KiCommand.new.execute(%W(version-import -h #{home.path} --move -c ki/sbt))
  end

  it "should run full build" do
    @tester.chdir(source = @tester.tmpdir)
    home = KiHome.new(@tester.tmpdir)

    create_ki_ant(home, source)
    create_ki_sbt(home, source)

    build_config = <<EOF
build_dependencies:
  - ki/ant
  - ki/sbt
before_install:
  - echo Before install >> result.txt
  - echo Test output
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
    v.version_id.should eq("test/result/1")
    IO.read(v.binaries.path("result.txt")).should eq("Before install
ANT
Before script 1
Before script 2
SBT 1000
INFO
After script
")
    log_path = home.repository("build").version!("test/result/1").path("ki-build-logs.json")
    logs = KiJSONFile.load_json(log_path)
    logs["version"].should eq("test/result/1")
    logs["ki-version"].should eq(KiHome.ki_version)
    logs["name"].should eq("Build")
    logs["logs"].map{|l| l["name"]}.should eq(["build_dependencies", "before_install", "install", "before_script", "script", "after_script"])
    logs["logs"][0]["logs"].map{|l| l["version"]}.should eq(["ki/ant/1", "ki/sbt/1"])
    first_shell_cmd = logs["logs"][1]["logs"][0]
    first_shell_cmd["name"].should eq("echo")
    first_shell_cmd["cmd"].should eq("echo Before install >> result.txt")
    second_shell_cmd = logs["logs"][1]["logs"][1]
    second_shell_cmd["name"].should eq("echo")
    second_shell_cmd["cmd"].should eq("echo Test output")
    second_shell_cmd["stdout"].should eq("Test output\n")
  end

  it "should execute build only if remote git changes" do
    @tester.chdir(build_dir = @tester.tmpdir)
    home = KiHome.new(@tester.tmpdir)

    create_ki_sbt(home, build_dir)

    build_config = <<EOF
build_dependencies: ki/sbt
script: ./sbt.sh
build_version:
  - result.txt
import_component: test/result
env:
  global:
    - TIMEOUT=1000
EOF

    git_dir = @tester.tmpdir
    git_sh = HashLogShell.new.chdir(git_dir).root_log(DummyHashLog.new)
    git_sh.spawn("git init")

    # create 1st version
    Tester.write_files(git_dir,
                       "info.txt" => "INFO
",
                       "ki.yml" => build_config
    )
    git_sh.spawn("git add *.*")
    git_sh.spawn("git commit -m 'initial commit'")

    Tester.write_files(build_dir, "ki-builds.json" => JSON.pretty_generate({builds: [{remote_url: git_dir + ":master"}]}))
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    v1 = home.version("test/result")
    v1.name.should eq("1")
    IO.read(v1.binaries.path("result.txt")).should eq("SBT 1000\nINFO\n")
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    home.version("test/result").name.should eq("1")

    # modify project and commit, create 2nd version
    Tester.write_files(git_dir,
                       "info.txt" => "WARN
"
    )
    git_sh.spawn("git add *.*")
    git_sh.spawn("git commit -m '2nd commit'")
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    v2 = home.version("test/result")
    v2.name.should eq("2")
    IO.read(v2.binaries.path("result.txt")).should eq("SBT 1000\nWARN\n")
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    home.version("test/result").name.should eq("2")
  end

  it "should execute product there are new components" do
    @tester.chdir(build_dir = @tester.tmpdir)
    home = KiHome.new(@tester.tmpdir)

    create_ki_sbt(home, build_dir)

    build_config = {products: [{component: "ki/product", dependencies: [{name: "sbt", source: "ki/sbt", path: "build"}]}]}
    Tester.write_files(build_dir, "ki-builds.json" => JSON.pretty_generate(build_config))
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    v1 = home.version("ki/product")
    v1.name.should eq("1")
    v1.metadata.dependencies.should eq([{"name"=>"sbt", "path"=>"build", "version_id"=>"ki/sbt/1"}])
    build_config_with_state = {
        "builds" => [],
        "products" => [
            {
                "component" => "ki/product",
                "dependencies" => [
                    {"name" => "sbt", "source" => "ki/sbt", "last_version" => "ki/sbt/1", "path" => "build"}
                ]
            }
        ]
    }
    Ki::Ci::CiBuildConfigFile.new("ki-builds.json").cached_data.should eq(build_config_with_state)

    # no changes, no new product version
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    home.version("ki/product").version_id.should eq("ki/product/1")

    # create new sbt, new product build produces new product
    create_ki_sbt(home, build_dir)
    KiCommand.new.execute(%W(ci-build-on-change -h #{home.path}))
    v2 = home.version("ki/product")
    v2.version_id.should eq("ki/product/2")
    v2.metadata.dependencies.should eq([{"name"=>"sbt", "path"=>"build", "version_id"=>"ki/sbt/2"}])
  end
end