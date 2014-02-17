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

describe Ki::Ci::RealtimeTaskScheduler do
  before do
    @scheduler = Ki::Ci::RealtimeTaskScheduler.new
  end

  it "runs tasks in dependency order" do
    arr = []
    @scheduler.add_task("a") do
      arr << "a"
    end.after("b","c")
    @scheduler.add_task("b") do
      arr << "b"
    end.after(["c"])
    @scheduler.add_task("c") do
      arr << "c"
    end
    @scheduler.run_all_tasks
    arr.should eq ["c", "b", "a"]
  end

  it "runs tasks based on how resources are limited" do
    arr = []
    ok = false
    @scheduler.add_limited_resource("r", 1)
    @scheduler.add_task("a") do
      sleep 0.1
      arr << "a"
    end.resources(["r"])
    @scheduler.add_task("b") do
      ok = arr == ["a"]
      arr << "b"
    end.resources(["r"])
    @scheduler.run_all_tasks
    arr.should eq ["a","b"]
    if !ok
      raise "A was not run fully before B!"
    end
  end

  it "runs all tasks even if first throws exception if task is IGNORE" do
    arr = []
    @scheduler.add_task("a") do
      arr << "a"
    end.after(["b"])
    @scheduler.add_task("b") do
      arr << "b"
      raise "error"
    end.on_error(Ki::Ci::RealtimeTaskScheduler::IGNORE)
    lambda{@scheduler.run_all_tasks}.should raise_error("error")
    arr.should eq ["b","a"]
  end

  it "stops running tasks on error" do
    arr = []
    @scheduler.add_task("a") do
      arr << "a"
    end.after(["b"])
    @scheduler.add_task("b") do
      arr << "b"
      raise "error"
    end
    lambda{@scheduler.run_all_tasks}.should raise_error("error")
    arr.should eq ["b"]
  end

  it "stops running tasks straight away" do
    arr = []
    @scheduler.add_task("a") do
      sleep 0.1
      arr << "a"
    end
    @scheduler.add_task("b") do
      arr << "b"
      raise "error"
    end.on_error(Ki::Ci::RealtimeTaskScheduler::STOP_NOW)
    lambda{@scheduler.run_all_tasks}.should raise_error("error")
    arr.should eq ["b"]
  end

  it "checks that tasks have a block" do
    lambda{@scheduler.add_task("a")}.should raise_error("Task 'a' needs to define a block!")
  end

  it "checks that task is is defined only once" do
    @scheduler.add_task("a"){}
    lambda{@scheduler.add_task("a"){}}.should raise_error("Task 'a' is already defined!")
  end

  it "checks that resource is is defined only once" do
    @scheduler.add_limited_resource("a"){}
    lambda{@scheduler.add_limited_resource("a")}.should raise_error("Resource 'a' is already defined!")
  end

  it "checks for issues with circular task definitions" do
    @scheduler.add_task("a"){}.after(["b"])
    @scheduler.add_task("b"){}.after(["a"])
    lambda{@scheduler.run_all_tasks}.should raise_error("Scheduled tasks have 2 issues: 'a' > 'b' > 'a' is a circular dependency path, 'b' > 'a' > 'b' is a circular dependency path")
  end

  it "checks for issues with undefined references" do
    @scheduler.add_task("a"){}.after(["c"])
    @scheduler.add_task("b"){}.resources(["d"])
    lambda{@scheduler.run_all_tasks}.should raise_error("Scheduled tasks have 2 issues: 'a' references undefined task 'c', 'b' references undefined resource 'd'")
  end

end