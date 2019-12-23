require "spec_helper"

RSpec.describe 'Configuration' do
  describe "#valid_query_params=" do
    context 'when correct value' do
      it "sets value" do
        JsonApiable.configure do |c|
          c.valid_query_params = %w[filter]
        end
  
        expect(JsonApiable.configuration.valid_query_params).to eq(%w[filter])
      end
    end
    
    context 'when invalid value' do
      it 'raises exception' do
        expect do
          JsonApiable.configure do |c|
            c.valid_query_params = 'kuku'
          end
        end.to raise_error(JsonApiable::ConfigurationError)
      end
    end
  end

  describe "#supported_media_type_proc=" do
    context 'when correct value' do
      it "sets value" do
        JsonApiable.configure do |c|
          c.supported_media_type_proc = proc do |request|
            request.content_type == JsonApiable::JSONAPI_CONTENT_TYPE ||
              request.headers['HTTP_IOS_APP_VERSION'].present?
          end
        end

        supported_media_type_proc = JsonApiable.configuration.supported_media_type_proc
        expect(supported_media_type_proc).to be_present
        expect(supported_media_type_proc).to be_a_kind_of(Proc)
      end
    end

    context 'when invalid value' do
      it 'raises exception' do
        expect do
          JsonApiable.configure do |c|
            c.supported_media_type_proc = 'kuku'
          end
        end.to raise_error(JsonApiable::ConfigurationError)
      end
    end
  end

  describe ".reset" do
    before :each do
      JsonApiable.configure do |config|
        config.valid_query_params = config.valid_query_params + %w[user_id]
      end
    end

    it "resets the configuration" do
      JsonApiable.reset

      config = JsonApiable.configuration

      expect(config.valid_query_params).to eq(%w[access_token filter include page])
    end
  end
end
