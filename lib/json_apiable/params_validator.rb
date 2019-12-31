module JsonApiable
  class ParamsValidator
    class DataParams
      def self.build(params, attributes, relationships)
        params.require(:data).permit(:id, :type,
                                     attributes: attributes,
                                     relationships: relationships)
      end
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
  end
end