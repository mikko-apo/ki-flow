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

require 'sinatra'

require_relative 'env/env'

require_relative 'actions/action_log_dir'
require_relative 'actions/action_base'
require_relative 'actions/action_log_web'

require_relative 'web/repository'
require_relative 'web/static_files'
require_relative 'web/web_util'
require_relative 'web/queue_rest'

require_relative 'ci/version_control/ci_git'
require_relative 'ci/ci_build'
require_relative 'ci/ci_build_on_change'
require_relative 'ci/builders/git_builds_builder'
require_relative 'ci/builders/product_builds_builder'
require_relative 'ci/ki_yml_build_config'

require_relative 'util/scheduler'
require_relative 'util/gzip'
require_relative 'util/resource_pool'
