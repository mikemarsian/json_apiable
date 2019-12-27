# frozen_string_literal: true
require 'rails_helper'

RSpec.describe API::UsersController, type: :controller do
  describe 'GET #index' do
    context 'media type' do
      context 'valid request' do
        subject(:get_index) { json_api_get :index }
        it 'is set in response' do
          get_index

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('application/vnd.api+json')
        end
      end

      context 'invalid request' do
        context 'media type is incorrect' do
          subject(:get_index) { get :index }
          it 'returns unsupported_media_type' do
            get_index

            expect(response).to have_http_status(:unsupported_media_type)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Unsupported Media Type',
                                                           'detail' => 'application/vnd.api+json is expected',
                                                           'status' => '415'
                                                       }] }.to_json)
          end

          context 'when media type block' do
            before do
              JsonApiable.configure do |config|
                config.supported_media_type_proc = proc do |request|
                  request.headers['My-Header'] == '123'
                end
              end
            end
            after do
              JsonApiable.reset
            end
            context 'is unsupported' do
              it 'returns unsupported media type' do
                get_index

                expect(response).to have_http_status(:unsupported_media_type)
              end
            end
            context 'is supported' do
              before do
                request.headers['My-Header'] = '123'
              end
              it 'returns ok' do
                get :index

                expect(response).to have_http_status(:ok)
              end
            end
          end
        end
      end
    end

    context 'pagination' do
        context 'valid request' do
          context 'both values provided' do
            subject(:get_index) { json_api_get :index, page: { number: 2, size: 2 } }

            it 'returns correct hash' do
              get_index

              expect(controller.jsonapi_page[:number]).to eq(2)
              expect(controller.jsonapi_page[:size]).to eq(2)
            end
          end

          context 'only page is given' do
            subject(:get_index) { json_api_get :index, page: { number: 2} }

            it 'returns correct hash' do
              get_index

              expect(controller.jsonapi_page[:number]).to eq(2)
              expect(controller.jsonapi_page[:size]).to eq(JsonApiable::JSONAPI_DEFAULT_PAGE_SIZE)
            end
          end

          context 'only size is given' do
            subject(:get_index) { json_api_get :index, page: { size: 2} }

            it 'returns correct hash' do
              get_index

              expect(controller.jsonapi_page[:number]).to eq(1)
              expect(controller.jsonapi_page[:size]).to eq(2)
            end
          end
        end

        context 'invalid request' do
          context 'one value is invalid' do
            subject(:get_index) { json_api_get :index, page: { number: 2, size: 'kuku' } }

            it 'returns bad_request' do
              get_index

              expect(response).to have_http_status(:bad_request)
              expect(response.body).to eq({ 'errors' => [{
                                                             'title' => 'Invalid Argument',
                                                             'detail' => 'page[size]',
                                                             'status' => '400'
                                                         }] }.to_json)
            end
          end
        end
      end

    context 'query params' do
      context 'invalid request' do
        it 'returns bad_request' do
        json_api_get :index, params: { kuku: 1 }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq({ 'errors' => [{
                                                       'title' => 'Invalid Argument',
                                                       'detail' => 'params',
                                                       'status' => '400'
                                                   }] }.to_json)
      end
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user) }
    subject(:get_show) { json_api_get :show, id: user_id }
    before do
      user
    end
    context 'valid request' do
      let(:user_id) { user.id }

      it 'returns ok' do
        get_show

        expect(response).to have_http_status(:ok)
      end
    end

    context 'invalid request' do
      let(:user_id) { 666 }
      it 'returns not_found' do
        get_show

        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq({ 'errors' => [{
                                                       'title' => 'Not Found',
                                                       'detail' => "Couldn't find User with 'id'=666",
                                                       'status' => '404'
                                                   }] }.to_json)
      end
    end
  end
end