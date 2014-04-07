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

require 'monitor.rb'

module Ki

  module Ci

    # Execute any number of Tasks. Tasks get executed based on how they depend on each other and resources.
    # Tasks are executed in parallel unless they have a dependency on another task or a limited resource is already being used.
    # This class can be used to execute a complex process in an optimized order.
    #
    # TODO:
    #
    # * A simple syntax/way to define tasks that are executed inside a task
    class RealtimeTaskScheduler
      attr_accessor :exception_catcher

      # If a task throws an exception, don't start new tasks and stop once all tasks are finished. Default behaviour
      STOP_GRACEFULLY = :stop_gracefully
      # If a task throws an exception, stop all processing
      STOP_NOW = :stop_now
      # Ignore all exceptions
      IGNORE = :ignore

      def initialize
        self.extend(MonitorMixin)
        @update_cond = new_cond
        @threads = []

        @tasks = Hash.new
        @running_tasks = Hash.new
        @completed_tasks = Hash.new
        @resources = Hash.new
        @on_error_default = STOP_GRACEFULLY

        @stop_gracefully = false
        @stop_now = false
      end

      def add_task(name, &block)
        if @tasks.include?(name)
          raise "Task '#{name}' is already defined!"
        end
        if block.nil?
          raise "Task '#{name}' needs to define a block!"
        end
        @tasks[name] = Task.new(&block).on_error(@on_error_default)
      end

      def add_limited_resource(name, max_tasks=1)
        if @resources.include?(name)
          raise "Resource '#{name}' is already defined!"
        end
        @resources[name] = LimitedResource.new.max_tasks(max_tasks)
      end

      def run_all_tasks
        if @exception_catcher.nil?
          @exception_catcher = ExceptionCatcher.new
        end
        check_integrity
        @exception_catcher.catch do
          execute_available_tasks
          while !finished
            synchronize { @update_cond.wait(2) }
            execute_available_tasks
          end
        end
        @exception_catcher.check
      end

      def check_integrity
        issues = []
        @tasks.each_pair do |t_name, task|
          task.resources.each do |resource_name|
            if !@resources.include? resource_name
              issues << "'#{t_name}' references undefined resource '#{resource_name}'"
            end
          end
          task.after.each do |task_name|
            if !@tasks.include? task_name
              issues << "'#{t_name}' references undefined task '#{task_name}'"
            end
          end
          check_circular_dependency([t_name], task, issues)
        end
        if issues.size > 0
          raise "Scheduled tasks have #{issues.size} issues: #{issues.join(", ")}"
        end
      end

      def check_circular_dependency(path, task, issues)
        task.after.each do |task_name|
          if @tasks.include? task_name
            new_path = path.clone
            new_path << task_name
            if path.include? task_name
              issues << "'#{new_path.join("' > '")}' is a circular dependency path"
            else
              check_circular_dependency(new_path, @tasks[task_name], issues)
            end
          end
        end
      end

      def finished
        synchronize do
          if @stop_now
            true
          elsif @stop_gracefully
            @threads.empty?
          else
            @tasks.empty? && @threads.empty?
          end
        end
      end

      def execute_available_tasks
        synchronize do
          launched = 0
          @tasks.to_a.each do |task_name, task|
            if @stop_now || @stop_gracefully
              return
            end
            if dependencies_completed(task.after) && resources_available(task.resources)
              launched += 1
              modify_resources(task.resources, +1)
              @tasks.delete(task_name)
              @running_tasks[task_name] = task
              @threads << Thread.new do
                exception = nil
                @exception_catcher.catch(task_name) do
                  begin
                    task.run
                  rescue Exception => e
                    exception = e
                    raise
                  end
                end
                if exception
                  handle_exception(task_name, task, exception)
                end
                release_task(Thread.current, task_name, task)
              end
            end
          end
          if launched == 0 && @tasks.size > 0 && @running_tasks.empty? && @completed_tasks.empty?
            raise "Deadlock! For some reason could not launch any tasks!"
          end
        end
      end

      def dependencies_completed(task_list)
        task_list.each do |task_name|
          if !@completed_tasks.include?(task_name)
            return false
          end
        end
        true
      end

      def resources_available(resource_list)
        resource_list.each do |resource_name|
          limited_resource = @resources.fetch(resource_name)
          if limited_resource.full?
            return false
          end
        end
        true
      end

      def modify_resources(resource_list, count)
        resource_list.each do |resource_name|
          @resources.fetch(resource_name).modify_use(count)
        end
      end

      def release_task(thread, task_name, task)
        synchronize do
          @running_tasks.delete(task_name)
          @completed_tasks[task_name] = task
          @threads.delete(thread)
          modify_resources(task.resources, -1)
          @update_cond.broadcast
        end
      end

      def handle_exception(task_name, task, e)
        if task.on_error == STOP_GRACEFULLY
          @stop_gracefully = true
        elsif task.on_error == STOP_NOW
          synchronize do
            @stop_now = true
            @update_cond.broadcast
          end
        end
      end

      class Task
        attr_chain :after, -> { Array.new}
        attr_chain :resources, -> { Array.new }
        attr_chain :on_error, -> { STOP_GRACEFULLY }
        def initialize(&block)
          @block = block
        end

        def run
          @block.call
        end
      end

      class LimitedResource
        attr_chain :max_tasks, -> {1}
        attr_chain :current_tasks, -> { 0 }

        def full?
          max_tasks == current_tasks
        end

        def modify_use(count)
          current_tasks(current_tasks + count)
        end
      end

    end

  end
end