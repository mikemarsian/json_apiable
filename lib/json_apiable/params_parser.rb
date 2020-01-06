module JsonApiable
  class ParamsParser
    class DataParams
      def self.build(params, attributes, relationships)
        params.require(:data).permit(:id, :type,
                                     attributes: attributes,
                                     relationships: relationships)
      end
    end

    # Convert JsonAPI request body into Rails params hash
    def self.parse_body_params(request, params, allowed_attributes, excluded_attributes,
                               allowed_relationships, excluded_relationships)
      permitted_params = validate_data_params!(params,
                                               allowed_attributes,
                                               hashify(allowed_relationships))
      attributes_hash = build_attributes_hash(permitted_params.dig(:attributes), excluded_attributes)
      relationships_hash = build_relationships_hash(permitted_params.dig(:relationships), excluded_relationships, request)
      attributes_hash.merge(relationships_hash)
    rescue ArgumentError, ActionController::UnpermittedParameters
      raise
    rescue StandardError => e
      raise Errors::MalformedRequestError, e.message
    end

    def self.validate_data_params!(params, attributes, relationships)
      permitted = DataParams.build(params, attributes, relationships)
      unpermitted = params.dig(:data)&.keys.to_a - permitted&.keys.to_a
      raise ArgumentError, "Unpermitted member: #{unpermitted.first}" if unpermitted.present?


      unpermitted_arguments = params.dig(:data, :attributes)&.keys.to_a - permitted.dig(:attributes)&.keys.to_a
      raise ArgumentError, "Unpermitted attribute: #{unpermitted_arguments.first}" if unpermitted_arguments.present?

      unpermitted_relationships = params.dig(:data, :relationships)&.keys.to_a - permitted.dig(:relationships)&.keys.to_a
      raise ArgumentError, "Unpermitted relationship: #{unpermitted_relationships.first}" if unpermitted_relationships.present?

      permitted
    end

    def self.build_attributes_hash(attributes, excluded_attributes)
      attrs_hash = {}
      attributes&.each do |key, value|
        next if excluded_attributes&.include?(key.to_sym)

        new_key = value.is_a?(ActionController::Parameters) ? "#{key}_attributes" : key
        attrs_hash[new_key] = value.is_a?(ActionController::Parameters) ? value.to_h : value
      end
      attrs_hash
    end

    def self.build_relationships_hash(relationships, excluded_relationships, request)
      attr_hash = {}; ids_array = []; ids_key = nil

      relationships&.each_pair do |key, data_hash|
        next if excluded_relationships&.include?(key.to_sym)

        if ActiveSupport::Inflector.pluralize(key) == key
          new_key = "#{key}_attributes"
          new_value = build_relationship_attribute_hash(data_hash)
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

    def self.build_relationship_attribute_hash(data_hash)
      attr_hash = {}
      data_hash['data'].each_with_index do |arr_item, i|
        item_hash = { 'id' => arr_item['id'], '_destroy' => 'false' }
        attr_hash[i.to_s] = item_hash
      end
      attr_hash
    end

    def self.hashify(allowed_relationships)
      allowed_relationships.map{|rel| { rel => {}}}
    end
  end
end