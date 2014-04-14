require_relative 'spec_helper'

describe ActionBaseDirectory do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "create action log directory structure" do
    tmp = @tester.tmpdir
    action_log_root = ActionBaseDirectory.new(tmp).log_roots
    action_log_root.path.should eq(File.join(tmp, "log_roots.json"))
    action_logs = action_log_root.add_item("a/b")
    action_logs.path.should eq(File.join(tmp, "a/b"))
    log_dirs = action_logs.log_dirs
    log_dirs.path.should eq(File.join(tmp, "a/b/log_dirs.json"))
    action_log_dir = action_logs.new_log_dir
    action_log_dir.path.should eq(File.join(tmp, "a/b/1"))
    log = action_log_dir.action_log
    log.path.should eq(File.join(tmp, "a/b/1/action_log.json"))
    log.save
    action_logs.new_log_dir.path.should eq(File.join(tmp, "a/b/2"))
  end

  class TestAction
    include ActionBase
  end

  it "ActionBase should log files from log directory" do
    action = TestAction.new
    tmp = @tester.tmpdir
    action.action_log_dir(ActionLogDir.new("123").parent(DirectoryBase.new(tmp)))
    action.write_log_file({})
    JSON.parse(IO.read(action.action_log_file.path)).should eq({})
    Tester.write_files(tmp, "123/a" => "txt")
    action.write_log_file({})
    JSON.parse(IO.read(action.action_log_file.path)).should eq({"files"=>["a"]})
  end
end