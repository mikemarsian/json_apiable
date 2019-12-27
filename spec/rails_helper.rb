# frozen_string_literal: true

require 'spec_helper'
require 'rails/all'
require 'rspec/rails'
require 'support/rails_app/config/environment'

ActiveRecord::Migration.maintain_test_schema!

# set up db
# be sure to update the schema if required by doing
# - cd spec/rails_app
# - rake db:migrate
ActiveRecord::Schema.verbose = false
load 'support/rails_app/db/schema.rb' # use db agnostic schema by default

def json_api_request(request_method, action, parameters = {}, session = nil, flash = nil)
  @request.headers['ACCEPT'] = 'application/vnd.api+json'
  @request.headers['CONTENT_TYPE'] = 'application/vnd.api+json'
  extra_headers = parameters[:headers] || {}
  extra_headers.each do |key, value|
    @request.headers[key] = value
  end
  parameters.delete :headers
  parameters[:format] = :json_api unless parameters&.key? :format
  __send__(request_method, action, params: parameters, session: session, flash: flash)
end
alias json_api :json_api_request

def json_api_delete(action, parameters = {}, session = nil, flash = nil)
  json_api_request(:delete, action, parameters, session, flash)
end

def json_api_get(action, parameters = {}, session = nil, flash = nil)
  json_api_request(:get, action, parameters, session, flash)
end

def json_api_patch(action, parameters = {}, session = nil, flash = nil)
  json_api_request(:patch, action, parameters, session, flash)
end
alias json_api_put :json_api_patch

def json_api_post(action, parameters = {}, session = nil, flash = nil)
  json_api_request(:post, action, parameters, session, flash)
end