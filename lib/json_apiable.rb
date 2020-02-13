# frozen_string_literal: true

require 'active_support/all'
require "json_apiable/version"
require "json_apiable/core_extensions"
require 'json_apiable/configuration'
require 'json_apiable/renderers'
require 'json_apiable/errors'
require 'json_apiable/params_parser'
require 'json_apiable/pagination_parser'
require 'json_apiable/filter_parser'
require 'json_apiable/filter_matchers'
require 'json_apiable/base_filter'
require 'json_apiable/json_apiable'

String.include CoreExtensions::String
Mime::Type.register JsonApiable::JSONAPI_CONTENT_TYPE, :json_api
