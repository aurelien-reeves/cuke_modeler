require 'bundler/gem_tasks'
require 'rake'
require 'rainbow'

Rainbow.enabled = true

require_relative 'cuke_modeler_project_settings'
require_relative 'cuke_modeler_helper'
require_relative 'rakefiles/ci_tasks'
require_relative 'rakefiles/documentation_tasks'
require_relative 'rakefiles/other_tasks'
require_relative 'rakefiles/release_tasks'
require_relative 'rakefiles/reporting_tasks'
require_relative 'rakefiles/testing_tasks'


task :default => 'cuke_modeler:test_everything' # rubocop:disable Style/HashSyntax
