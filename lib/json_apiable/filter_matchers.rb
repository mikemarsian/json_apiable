# frozen_string_literal: true

module JsonApiable
  module FilterMatchers
    def matches?(allowed, given)
      given.all? do |value|
        allowed.is_a?(Proc) ? allowed.call(value) : allowed.include?(value)
      end
    end

    module_function :matches?

    # returns true for boolean values, false for any other
    def boolean_matcher
      proc do |value|
        handle_error(value) do
          if true_matcher.call(value) || (value == false || value =~ /^(false|f|0)$/i)
            true
          else
            false
          end
        end
      end
    end

    # returns true for true values, false for any other
    def true_matcher
      proc do |value|
        handle_error(value) do
          if value == true || value =~ /^(true|t|1)$/i
            true
          else
            false
          end
        end
      end
    end

    # returns true if the value is a valid date or datetime
    def datetime_matcher
      proc do |value|
        handle_error(value) do
          datetime = value.in_time_zone(Time.zone)
          datetime.present?
        end
      end
    end

    # returns true if the value is a an array of existing ids of the given model
    def ids_matcher(model)
      proc do |value|
        handle_error(value) do
          given_ids = value.split(',')
          found_records = model.where(id: given_ids)

          given_ids.count == found_records.count
        end
      end
    end

    def handle_error(value)
      yield
    rescue ArgumentError => e
      raise ArgumentError, "#{value}: #{e.message}"
    end
  end
end
