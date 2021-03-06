# frozen_string_literal: true

module JsonApiable
  class Configuration
    attr_accessor :valid_query_params, :supported_media_type_proc, :not_found_exception_class, :page_size

    DEFAULT_PAGE_NUMBER = 1
    DEFAULT_PAGE_SIZE = 25
    # 2^32 / 2 * 10: greater than which raises a java.lang.ArrayIndexOutOfBoundsException exception in Solr
    MAX_PAGE_SIZE = 214_748_364

    def initialize
      @valid_query_params = %w[id user_id access_token filter include page]
      @supported_media_type_proc = nil
      @not_found_exception_class = ActiveRecord::RecordNotFound
      @page_size = DEFAULT_PAGE_SIZE
    end

    def valid_query_params=(value)
      raise JsonApiable::ConfigurationError, 'Should be an array containing strings' unless value.is_a?(Array)
      @valid_query_params = value
    end

    def supported_media_type_proc=(prok)
      raise JsonApiable::ConfigurationError, 'Should be a proc' unless prok.is_a?(Proc)
      @supported_media_type_proc = prok
    end

    def not_found_exception_class=(klass)
      raise JsonApiable::ConfigurationError, 'Should be a class' unless klass.is_a?(Class)
      @not_found_exception_class = klass
    end
  end
end
