require 'active_support/all'
require "json_apiable/version"
require "json_apiable/core_extensions"
require 'json_apiable/configuration'
require 'json_apiable/renderers'
require 'json_apiable/errors'
require 'json_apiable/json_apiable'

String.include CoreExtensions::String