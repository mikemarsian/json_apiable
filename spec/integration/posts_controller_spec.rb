# frozen_string_literal: true
require 'rails_helper'

RSpec.describe API::PostsController, type: :controller do
  describe 'GET #index' do
    context 'include' do
      context 'valid request' do
        context 'non-empty include' do
          subject(:get_index) { json_api_get :index, include: 'author, posts' }
          it 'include is set' do
            get_index

            expect(controller.jsonapi_include).to eq([:author, :posts])
          end
        end
        context 'empty include' do
          subject(:get_index) { json_api_get :index, include: '' }
          it 'include is set' do
            get_index

            expect(controller.jsonapi_include).to eq([])
          end
        end
      end
    end
  end
end