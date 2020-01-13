# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require 'rubygems'
require 'pry'
require 'factory_bot'
require 'factory_bot_rails'
require "json_apiable"
require 'rails-controller-testing'

Rails::Controller::Testing.install

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each do |file|
  # skip the dummy app
  next if file.include?('support/rails_app')

  require file
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.order = 'random'
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
