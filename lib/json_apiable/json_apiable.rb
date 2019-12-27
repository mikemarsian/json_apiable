module JsonApiable
  extend ActiveSupport::Concern
  include Errors
  include Renderers

  JSONAPI_CONTENT_TYPE = 'application/vnd.api+json'
  JSONAPI_DEFAULT_PAGE_NUMBER = 1
  JSONAPI_DEFAULT_PAGE_SIZE = 25

  attr_reader :jsonapi_page

  included do
    before_action :ensure_content_type
    before_action :ensure_valid_query_params
    before_action :parse_pagination

    after_action :set_content_type

    rescue_from ArgumentError, with: :respond_to_bad_argument
    rescue_from MalformedRequestError, with: :respond_to_malformed_request
    rescue_from CapabilityError, with: :respond_to_capability_error
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

  def ensure_content_type
    respond_to_unsupported_media_type unless supported_media_type?
  end

  def ensure_valid_query_params
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

  def set_content_type
    response.headers['Content-Type'] = JSONAPI_CONTENT_TYPE
  end

  def parse_pagination
    if api_params[:no_pagination]
      @jsonapi_page = nil
    elsif api_params[:page].present? && !api_params[:page].is_a?(ActionController::Parameters)
      respond_to_bad_argument('page')
    elsif api_params.dig(:page, :number).present? && !api_params.dig(:page, :number).integer?
      respond_to_bad_argument('page[number]')
    elsif api_params.dig(:page, :size).present? && !api_params.dig(:page, :size).integer?
      respond_to_bad_argument('page[size]')
    else
      @jsonapi_page = api_params[:page].presence.to_h.with_indifferent_access
      @jsonapi_page = @jsonapi_page.merge(@jsonapi_page) { |k,v| v.to_i } if @jsonapi_page.present?
      @jsonapi_page = { number: JSONAPI_DEFAULT_PAGE_NUMBER, size: JsonApiable.configuration.page_size } if @jsonapi_page.blank?
      @jsonapi_page[:number] = JSONAPI_DEFAULT_PAGE_NUMBER if @jsonapi_page[:number].blank?
      @jsonapi_page[:size] = JsonApiable.configuration.page_size if @jsonapi_page[:size].blank?
    end
  end

  def api_params
    params.permit(page: {}, filter: {})
  end

end