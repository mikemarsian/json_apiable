module JsonApiable
  module Errors
    class ApiError < StandardError; end
    class MalformedRequestError < ApiError; end
    class CapabilityError < ApiError; end
    class UnprocessableEntityError < ApiError; end
    class UnauthorizedError < ApiError; end
    class ForbiddenError < ApiError; end
    class ConfigurationError < ApiError; end
  end
end