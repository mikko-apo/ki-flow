require_relative 'spec_helper'

describe BackgroundLooper do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "create action log directory structure" do
    tmp = @tester.tmpdir
    bl = BackgroundLooper.new
    c = 0
    file = File.join(tmp, "test.txt")
    bl.run(0.01) do
      c += 1
      File.safe_write(file, "#{c}")
    end
    sleep 0.03
    read1 = IO.read(file).to_i
    read1.should be > 0
    sleep 0.02
    read2 = IO.read(file).to_i
    read2.should be > read1
  end

end