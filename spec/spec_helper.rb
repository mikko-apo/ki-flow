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

require 'rubygems'
require 'rspec'
require 'mocha/api'
require 'rack/test'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.include Rack::Test::Methods
end

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

if File.exists?(local_ki_repo = File.expand_path(File.join(__FILE__, "../../../ki-repo/lib/ki_repo_all.rb")))
  require local_ki_repo
else
  require 'ki_repo_all'
end

require 'ki_flow'

include Ki

# Override user's own ki-repository settings
ENV["KIHOME"]=File.dirname(File.dirname(File.expand_path(__FILE__)))

# common helper methods

def try(retries, retry_sleep, &block)
  c = 0
  start = Time.now
  while c < retries
    begin
      return block.call(c+1)
    rescue Exception => e
      c += 1
      if c < retries
        sleep retry_sleep
      else
        raise e.class, e.message + " (tried #{c} times, waited #{sprintf("%.2f", Time.now - start)} seconds)", e.backtrace
      end
    end
  end
end

def restore_extensions
  original_commands = KiCommand::KiExtensions.dup
  @tester.cleaners << lambda do
    KiCommand::KiExtensions.clear
    KiCommand::KiExtensions.register(original_commands)
  end
end

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

