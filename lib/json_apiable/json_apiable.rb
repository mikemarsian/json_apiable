module JsonApiable
  extend ActiveSupport::Concern
  include Errors
  include Renderers

  JSONAPI_CONTENT_TYPE = 'application/vnd.api+json'

  included do
    before_action :ensure_content_type
    before_action :ensure_valid_query_params

    after_action :set_content_type

    rescue_from ArgumentError, with: :respond_to_bad_argument
    rescue_from MalformedRequestError, with: :respond_to_malformed_request
    rescue_from CapabilityError, with: :respond_to_capability_error
    rescue_from UnprocessableEntityError, with: :respond_to_unprocessable_entity
    rescue_from UnauthorizedError, with: :respond_to_unauthorized
    rescue_from ForbiddenError, with: :respond_to_forbidden
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

  def ensure_content_type
    respond_to_unsupported_media_type unless supported_media_type?
  end

  def ensure_valid_query_params
    invalid_params = request.query_parameters.keys.reject { |k| JsonapiRailsUtils.configuration.valid_query_params.include?(k) }
    respond_to_bad_argument(invalid_params.first) if invalid_params.present?
  end

  def supported_media_type?
    if JsonApiable.configuration.supported_media_type_proc.present?
      JsonApiable.configuration.supported_media_type_proc.call(request)
    else
      request.content_type == JSONAPI_CONTENT_TYPE
    end
  end

  def set_content_type
    response.headers['Content-Type'] = JSONAPI_CONTENT_TYPE
  end

end