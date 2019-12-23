module JsonApiable
  class Configuration
    attr_accessor :valid_query_params, :supported_media_type_proc

    def initialize
      @valid_query_params = %w[access_token filter include page]
      @supported_media_type_proc = nil
    end

    def valid_query_params=(value)
      raise JsonApiable::ConfigurationError, 'Should be an array containing strings' unless value.is_a?(Array)
      @valid_query_params = value
    end

    def supported_media_type_proc=(prok)
      raise JsonApiable::ConfigurationError, 'Should be a proc' unless prok.is_a?(Proc)
      @supported_media_type_proc = prok
    end
  end
end