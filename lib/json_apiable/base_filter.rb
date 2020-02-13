# frozen_string_literal: true

module JsonApiable
  # Base class for Filters
  class BaseFilter
    extend JsonApiable::FilterMatchers

    attr_reader :jsonapi_collection, :jsonapi_filter_hash, :current_user

    protected

    def initialize(a_collection, a_filter_hash, current_user)
      @jsonapi_collection = a_collection
      @jsonapi_filter_hash = a_filter_hash
      @current_user = current_user
    end

    class << self
      def jsonapi_allowed_filters
        {}
      end
    end
  end
end
