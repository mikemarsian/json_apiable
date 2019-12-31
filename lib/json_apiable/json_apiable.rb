module JsonApiable
  extend ActiveSupport::Concern
  include Errors
  include Renderers

  JSONAPI_CONTENT_TYPE = 'application/vnd.api+json'
  JSONAPI_DEFAULT_PAGE_NUMBER = 1
  JSONAPI_DEFAULT_PAGE_SIZE = 25

  attr_reader :jsonapi_page, :jsonapi_include, :jsonapi_assign_params

  included do
    before_action :ensure_content_type
    before_action :ensure_valid_query_params
    before_action :parse_pagination
    before_action :parse_include

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

  def jsonapi_assign_params
    @jsonapi_assign_params ||= parse_request_body
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_attributes
    %w[]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_complex_attributes
    %w[]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_relationships
    %w[]
  end

  # Convert JsonAPI request body into Rails params hash. If error occurs, block is yielded
  def parse_request_body
    permitted = ParamsValidator.validate_data_params!(params,
                                                jsonapi_allowed_attributes,
                                                jsonapi_allowed_relationships.map{|rel| { rel => {}}})
    rel_hash = build_relationships_hash(permitted.dig(:relationships))
    attr_hash = permitted.dig(:attributes)&.to_h&.merge(rel_hash)
    attr_hash
  rescue ArgumentError
    raise
  rescue StandardError => e
    raise Errors::MalformedRequestError, e.message
  end

  def build_relationships_hash(relationship_params)
    attr_hash = {}; ids_array = []; ids_key = nil

    relationship_params&.each_pair do |key, data_hash|
      if ActiveSupport::Inflector.pluralize(key) == key
        new_key = "#{key}_attributes"
        new_value = build_attributes_hash(data_hash)
        ids_key = "#{ActiveSupport::Inflector.singularize(key)}_ids"
        ids_array = data_hash['data']&.map { |h| h['id'] }
      else
        new_key = "#{key}_id"
        new_value = data_hash['data']['id']
      end
      attr_hash[new_key] = new_value
      # ids array is needed when creating a new AR object which accepts_nested_attributes for existing AR object(s)
      # as in the case of a new Message which accepts existing attachments
      # https://stackoverflow.com/a/25943832/1983833
      attr_hash[ids_key] = ids_array if ids_array.present? && (request.post? || request.patch?)
    end
    attr_hash
  end

  def build_attributes_hash(data_hash)
    attr_hash = {}
    data_hash['data'].each_with_index do |arr_item, i|
      item_hash = { 'id' => arr_item['id'], '_destroy' => 'false' }
      attr_hash[i.to_s] = item_hash
    end
    attr_hash
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

  def parse_include
    @jsonapi_include = api_params[:include].presence&.gsub(/ /, '')&.split(',')&.map(&:to_sym).to_a
  end

  def api_params
    params.permit(:include, page: {}, filter: {})
  end

  def data_params_excluding_relationships
    JSONAPI_DATA_MEMBERS - %w[relationships]
  end

  def data_params_excluding_attributes
    JSONAPI_DATA_MEMBERS - %w[attributes]
  end

end