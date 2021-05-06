# frozen_string_literal: true

module JsonApiable
  module Renderers
    def respond_to_unsupported_media_type
      errors = [{ title: 'Unsupported Media Type', detail: 'application/vnd.api+json is expected' }]
      json_render_errors json: errors, status: :unsupported_media_type
    end

    def respond_to_unprocessable_entity(err_msg = nil)
      errors = [{ title: 'Unprocessable', detail: err_msg.to_s }]
      json_render_errors json: errors, status: :unprocessable_entity
    end

    def respond_to_forbidden(err_msg = nil)
      errors = [{ title: 'Forbidden', detail: err_msg.to_s || 'You are not authorized to perform this action' }]
      json_render_errors json: errors, status: :forbidden
    end

    def respond_to_unauthorized(err_msg = nil)
      errors = [{ title: 'Unauthorized', detail: err_msg.to_s || 'You have to be authenticated to perform this action' }]
      json_render_errors json: errors, status: :unauthorized
    end

    def respond_to_not_found(err_msg = nil)
      errors = [{ title: 'Not Found', detail: err_msg.to_s || 'Resource not found on the server' }]
      json_render_errors json: errors, status: :not_found
    end

    def respond_to_bad_argument(err_msg)
      errors = [{ title: 'Invalid Argument', detail: err_msg.to_s }]
      json_render_errors json: errors, status: :bad_request
    end

    def respond_to_exception_raised(err_msg)
      errors = [{ title: 'Invalid Argument', detail: err_msg.message }]
      json_render_errors json: errors, status: :bad_request
    end

    def respond_to_malformed_request(err_msg = nil)
      errors = [{ title: 'Malformed Request', detail: err_msg.to_s }]
      json_render_errors json: errors, status: :bad_request
    end

    def respond_to_capability_error
      errors = [{ title: 'Capability Error', detail: "Your plan doesn't allow this action" }]
      json_render_errors json: errors, status: :forbidden
    end

    def json_render_errors(json: nil, status: nil)
      err_json = json.first
      if err_json.present? && err_json[:status].blank?
        status_code = status.is_a?(Symbol) ? Rack::Utils::SYMBOL_TO_STATUS_CODE[status] : status
        err_json[:status] = status_code.to_s
      end
      render json: { errors: json }, status: status
    end
  end
end
