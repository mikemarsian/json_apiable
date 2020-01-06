module JsonApiable
  class PaginationParser

    def self.parse_pagination!(query_params, default_page_size)
      PaginationParser.new(query_params[:page], query_params[:no_pagination], default_page_size).parse!
    end

    attr_reader :page_param, :no_pagination, :default_page_size

    def initialize(page_arg, no_pagination_arg, default_page_size)
      @page_param = page_arg
      @no_pagination = no_pagination_arg
      @default_page_size = default_page_size
    end

    def parse!
      if no_pagination
        jsonapi_page = nil
      elsif invalid_page_param?
        raise ArgumentError, 'page'
      elsif invalid_page_number?
        raise ArgumentError, 'page[number]'
      elsif invalid_page_size?
        raise ArgumentError, 'page[size]'
      else
        jsonapi_page = page_param.presence.to_h.with_indifferent_access
        # convert values to integers
        jsonapi_page = jsonapi_page.merge(jsonapi_page) { |k,v| v.to_i } if jsonapi_page.present?
        jsonapi_page = { number: Configuration::DEFAULT_PAGE_NUMBER, size: default_page_size } if jsonapi_page.blank?
        jsonapi_page[:number] = Configuration::DEFAULT_PAGE_NUMBER if jsonapi_page[:number].blank?
        jsonapi_page[:size] = default_page_size if jsonapi_page[:size].blank?
      end
      jsonapi_page
    end

    private

    def invalid_page_param?
      page_param.present? && !page_param.is_a?(HashWithIndifferentAccess)
    end

    def invalid_page_number?
      page_num_param = page_param&.dig(:number)
      page_num_param.present? && invalid_number?(page_num_param)
    end

    def invalid_page_size?
      page_size_param = page_param&.dig(:size)
      page_size_param.present? && invalid_number?(page_size_param)
    end

    def invalid_number?(number_param)
      return true unless number_param.integer?

      number = number_param.to_i
      number > Configuration::MAX_PAGE_SIZE || number.zero? || number.negative?
    end
  end
end