require_relative 'spec_helper'

describe ResourcePool do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @pool = ResourcePool.new("pool.json").parent(DirectoryBase.new(@tester.tmpdir))
  end

  after do
    @tester.after
  end

  it "should reserve and free" do
    id = "myid"
    @pool.reserve(id).should eq(nil)
    @pool.edit_data do |pool|
      pool.cached_data= {"a" => "1"}
    end
    @pool.reserve(id).should eq("a")
    @pool.reserve(id).should eq(nil)
    lambda { @pool.free("a", 123) }.should raise_error("Can't free resource a. It's reserved for 'myid' and 123 tried to free it!")
    @pool.reserve(id).should eq(nil)
    @pool.free("a", id)
    @pool.reserve(id).should eq("a")
  end

  it "should claim, reserve and free" do
    id = "myid"
    id2 = "myid2"
    @pool.claim_for_other(10, id).should eq(nil)
    @pool.edit_data do |pool|
      pool.cached_data= {"a" => "1"}
    end
    lambda { @pool.reserve_claim(id2, "a:qweqe") }.should raise_error("Resource a not claimed!")
    claim_key = @pool.claim_for_other(10, id)
    arr = claim_key.split(":")
    arr[0].should eq("a")
    claim_id = arr[1]
    arr.size.should eq(2)
    @pool.reserve(id).should eq(nil)
    lambda { @pool.free("a", 123) }.should raise_error("Can't free resource a. It's claimed for 'myid'!")
    @pool.reserve(id).should eq(nil)
    lambda { @pool.reserve_claim(id2, "1adasd:qweqe") }.should raise_error("Resource 1adasd does not exist!")
    lambda { @pool.reserve_claim(id2, "a:qweqe") }.should raise_error("Resource a claimed with id qweqe different from #{claim_id}!")
    @pool.reserve_claim(id2, claim_key).should eq("a")
  end


end