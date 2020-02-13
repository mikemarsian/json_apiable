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

              expect(controller.jsonapi_page_hash[:number]).to eq(2)
              expect(controller.jsonapi_page_hash[:size]).to eq(2)
            end
          end

          context 'only page is given' do
            subject(:get_index) { json_api_get :index, page: { number: 2} }

            it 'returns correct hash' do
              get_index

              expect(controller.jsonapi_page_hash[:number]).to eq(2)
              expect(controller.jsonapi_page_hash[:size]).to eq(JsonApiable::Configuration::DEFAULT_PAGE_SIZE)
            end
          end

          context 'only size is given' do
            subject(:get_index) { json_api_get :index, page: { size: 2} }

            it 'returns correct hash' do
              get_index

              expect(controller.jsonapi_page_hash[:number]).to eq(1)
              expect(controller.jsonapi_page_hash[:size]).to eq(2)
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

  describe 'PATCH #update' do
    let(:user) { create(:user) }
    let(:new_name) { 'John Doe' }
    subject(:patch_update) { json_api_patch :update, id: user.id, data: update_json }

    context 'update attribute' do
      context 'valid' do
        let(:update_json) do
          {
              "type": 'user',
              "id": user.id,
              "attributes": {
                  "name": new_name
              }
          }
        end
        it 'returns ok' do
          patch_update

          expect(response).to have_http_status(:ok)
        end

        context 'jsonapi_attribute' do
          it 'when value exists' do
            patch_update

            expect(assigns(:name)).to eq(new_name)
          end

          it 'when value does not exist' do
            patch_update

            expect(assigns(:email)).to be_blank
          end
        end
      end

      context 'invalid' do
        context 'is not allowed' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                    "date_of_birth": '1980-12-12'
                }
            }
          end

          it 'returns bad_request' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :date_of_birth',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'is not sane' do
          let(:update_json) do
            {
              "type": 'user',
              "id": user.id,
              "foo": 'bar',
              "attributes": {
                  "name": 'Joe Doe'
              }
            }
          end

          it 'returns bad_request' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :foo',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'has no data' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                    "name": 'Joe Doe'
                }
            }
          end
          subject(:patch_update) { json_api_patch :update, id: user.id, dada: update_json }

          it 'returns bad_request' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Malformed Request',
                                                           'detail' => 'param is missing or the value is empty: data',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end
      end
    end

    context 'update complex attribute' do
      context 'valid' do
        let(:update_json) do
          {
              "type": 'user',
              "id": user.id,
              "attributes": {
                  "address":
                      { "street": 'st. Main 10, Apt. 10',
                        "city": 'New York',
                        "state_code": 'NY',
                        "zip_code": '11100',
                        "country_code": 'US'
                      }
              }
          }
        end
        it 'returns ok' do
          patch_update

          expect(response).to have_http_status(:ok)
        end
        it 'updates address' do
          expect { patch_update }.to change { user.reload.address.present? }.from(false).to(true)

          address = user.address
          expect(address.street).to eq('st. Main 10, Apt. 10')
          expect(address.city).to eq('New York')
          expect(address.state_code).to eq('NY')
          expect(address.zip_code).to eq('11100')
          expect(address.country_code).to eq('US')
        end
      end

      context 'invalid' do
        context 'nested param is not allowed' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                    "address": {
                        "primary_street": 'st. Main 10, Apt. 10',
                        "city": 'New York',
                        "state_code": 'NY',
                        "zip_code": '11100',
                        "country_code": 'US'
                    }
                }
            }
          end

          it 'returns bad_request' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :primary_street',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'complex param is not allowed' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                    "addrez": {
                        "primary_street": 'st. Main 10, Apt. 10',
                        "city": 'New York',
                        "state_code": 'NY',
                        "zip_code": '11100',
                        "country_code": 'US'
                    }
                }
            }
          end

          it 'returns bad_request' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :addrez',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end
      end
    end

    context 'update relationships' do
      let(:post) { create(:post) }
      let(:post2) { create(:post) }
      context 'valid request' do
        let(:update_json) do
          {
              "type": 'user',
              "id": user.id,
              "attributes": {
              },
              "relationships": {
                  "posts": {
                      "data": [
                          { "type": 'post', "id": post.id.to_s },
                          { "type": 'post', "id": post2.id.to_s }
                      ]
                  }
              }
          }
        end
        it 'returns ok' do
          patch_update

          expect(response).to have_http_status(:ok)
          expect(user.reload.posts).to include(post, post2)
        end
      end

      context 'invalid request' do
        let(:comment) { create(:comment) }
        context 'unpermitted' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                },
                "relationships": {
                    "comments": {
                        "data": [
                            { "type": 'comment', "id": comment.id.to_s }
                        ]
                    }
                }
            }
          end
          it 'returns bad_requets' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :comments',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'malformed' do
          let(:update_json) do
            {
                "type": 'user',
                "id": user.id,
                "attributes": {
                },
                "relationship": {
                    "posts": {
                        "data": [
                            { "type": 'post', "id": post.id.to_s }
                        ]
                    }
                }
            }
          end
          it 'returns bad_requets' do
            patch_update

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'found unpermitted parameter: :relationship',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end
      end
    end
  end
end
