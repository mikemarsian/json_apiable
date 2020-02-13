# frozen_string_literal: true

module JsonApiable
  class FilterParser
    def self.parse_filters!(jsonapi_build_params, filter_class)
      FilterParser.new(jsonapi_build_params[:filter], filter_class).parse!
    end

    attr_reader :filter_param, :filter_class

    def initialize(filter_param, filter_class)
      @filter_param = filter_param
      @filter_class = filter_class
    end

    # Support filtering in the form of example.com/v1/posts?filter[status]=draft,published
    def parse!
      raise_invalid_filter_class unless valid_filter_class?

      filter_hash = ActiveSupport::HashWithIndifferentAccess.new
      if valid_filter_query?
        filter_param.keys.each do |k|
          if valid_filter_key?(k)
            # support notation ?filter[param]=value1,value2,value3&...
            requested = filter_param[k].split(',')
            allowed_values = allowed_filter_keys[k]
            raise_invalid_filter_value(k) unless FilterMatchers.matches?(allowed_values, requested)

            filter_hash[k] = requested
          else
            raise_invalid_filter_value(k)
          end
        end
      elsif filter_param.present?
        raise ArgumentError, 'filter'
      end
      filter_hash
    end

    private

    def raise_argument_error(message)
      raise ArgumentError, message
    end

    def raise_invalid_filter_value(k)
      prefix = "filter[#{k}]"
      msg = filter_param[k].present? ? "#{prefix}=#{filter_param[k]}" : prefix
      raise_argument_error(msg)
    end

    def raise_invalid_filter_class
      raise_argument_error("#{filter_class} does not specify jsonapi_allowed_filters")
    end

    def valid_filter_class?
      filter_class.respond_to?(:jsonapi_allowed_filters)
    end

    def valid_filter_query?
      filter_param.present? && (filter_param.is_a?(Hash) || filter_param.is_a?(ActionController::Parameters))
    end

    def valid_filter_key?(k)
      allowed_filter_keys.key?(k) && filter_param[k].present?
    end

    def allowed_filter_keys
      filter_class.jsonapi_allowed_filters.with_indifferent_access
    end
  end
end
