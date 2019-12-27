# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'index' do
    subject { get :index }
    context 'valid request' do
      context 'media type is not set in response' do
        it 'returns ok' do
          subject

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end