# frozen_string_literal: true

module JsonApiable
  extend ActiveSupport::Concern
  include Errors
  include Renderers

  JSONAPI_CONTENT_TYPE = 'application/vnd.api+json'

  attr_reader :jsonapi_page_hash, :jsonapi_include_array, :jsonapi_filter_hash, :jsonapi_filter_class, :jsonapi_build_params,
              :jsonapi_assign_params, :jsonapi_default_page_size, :jsonapi_exclude_attributes, :jsonapi_exclude_relationships

  included do
    before_action :ensure_jsonapi_content_type
    before_action :ensure_jsonapi_valid_query_params
    before_action :parse_jsonapi_pagination
    before_action :parse_jsonapi_include

    after_action :set_jsonapi_content_type

    rescue_from ArgumentError, with: :respond_to_bad_argument
    rescue_from ActionController::UnpermittedParameters, with: :respond_to_bad_argument
    rescue_from MalformedRequestError, with: :respond_to_malformed_request
    rescue_from UnprocessableEntityError, with: :respond_to_unprocessable_entity
    rescue_from UnauthorizedError, with: :respond_to_unauthorized
    rescue_from ForbiddenError, with: :respond_to_forbidden
    rescue_from JsonApiable.configuration.not_found_exception_class, with: :respond_to_not_found
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def jsonapi_attribute(attrib_key)
    jsonapi_build_params.dig(:data, :attributes, attrib_key)
  end

  def jsonapi_attribute_present?(attrib_key)
    jsonapi_attribute(attrib_key).present?
  end

  def jsonapi_relationship(attrib_key)
    jsonapi_build_params.dig(:data, :relationships, attrib_key)
  end

  def jsonapi_relationship_data(attrib_key)
    jsonapi_build_params.dig(:data, :relationships, attrib_key, :data)
  end

  def jsonapi_relationship_present?(attrib_key)
    jsonapi_relationship(attrib_key).present?
  end

  def jsonapi_relationship_attribute(relationship, attribute)
    if [:id, :type].include?(attribute.to_sym)
      jsonapi_relationship_data(relationship)&.dig(attribute)
    else
      jsonapi_relationship_data(relationship)&.dig(:attributes, attribute)
    end
  end

  def jsonapi_assign_params
    return @jsonapi_assign_params if @jsonapi_assign_params.present? && !@invalidate_assign_params

    @jsonapi_assign_params = ParamsParser.parse_body_params(request,
                                                            jsonapi_build_params,
                                                            jsonapi_allowed_attributes,
                                                            jsonapi_exclude_attributes,
                                                            jsonapi_allowed_relationships,
                                                            jsonapi_exclude_relationships)
    @invalidate_assign_params = false
    @jsonapi_assign_params
  end

  def jsonapi_exclude_attribute(attrib_key)
    @jsonapi_exclude_attributes ||= []
    @jsonapi_exclude_attributes << attrib_key.to_sym
    @invalidate_assign_params = true
    jsonapi_build_params.dig(:data, :attributes, attrib_key)
  end

  def jsonapi_exclude_relationship(rel_key)
    @jsonapi_exclude_relationships ||= []
    @jsonapi_exclude_relationships << rel_key.to_sym
    @invalidate_assign_params = true
    jsonapi_build_params.dig(:data, :relationships, rel_key)
  end

  # Should be overwritten in specific controllers. If you need to manipulate params before they are parsed,
  # that's the place to do it
  def jsonapi_build_params
    params
  end

  # Should be overwritten in specific controllers
  def jsonapi_default_page_size
    JsonApiable.configuration.page_size
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_attributes
    %i[]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_relationships
    %i[]
  end

  def ensure_jsonapi_content_type
    respond_to_unsupported_media_type unless supported_media_type?
  end

  def ensure_jsonapi_valid_query_params
    invalid_params = request.query_parameters.keys.reject { |k| JsonApiable.configuration.valid_query_params.include?(k) }
    respond_to_bad_argument(invalid_params.first) if invalid_params.present?
  end

  def supported_media_type?
    if JsonApiable.configuration.supported_media_type_proc.present?
      JsonApiable.configuration.supported_media_type_proc.call(request)
    else
      request.content_type == JSONAPI_CONTENT_TYPE
    end
  end

  def set_jsonapi_filter(filter_class)
    @jsonapi_filter_class = filter_class
    @jsonapi_filter_hash = FilterParser.parse_filters!(jsonapi_build_params, filter_class)
  end

  def set_jsonapi_content_type
    response.headers['Content-Type'] = JSONAPI_CONTENT_TYPE
  end

  def parse_jsonapi_pagination
    @jsonapi_page_hash = PaginationParser.parse_pagination!(query_params, jsonapi_default_page_size)
  end

  def parse_jsonapi_include
    @jsonapi_include_array = query_params[:include].presence&.gsub(/ /, '')&.split(',')&.map(&:to_sym).to_a
  end

  def query_params
    request.query_parameters
  end
end
