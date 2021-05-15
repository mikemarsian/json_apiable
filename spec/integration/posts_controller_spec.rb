# frozen_string_literal: true
require 'rails_helper'

RSpec.describe API::PostsController, type: :controller do
  describe 'GET #index' do
    context 'include' do
      context 'valid request' do
        context 'non-empty include' do
          subject(:get_index) { json_api_get :index, include: 'user, posts' }
          it 'include is set' do
            get_index

            expect(controller.jsonapi_include_array).to eq([:user, :posts])
          end
        end
        context 'empty include' do
          subject(:get_index) { json_api_get :index, include: '' }
          it 'include is set' do
            get_index

            expect(controller.jsonapi_include_array).to eq([])
          end
        end
      end
    end

    context 'filters' do
      context 'valid request' do
        subject(:get_index) { json_api_get :index, filter: { status: 'draft,in_review' } }
        context 'array filter' do
          it 'filter is set' do
            get_index

            expect(response).to have_http_status(:ok)
            expect(controller.jsonapi_filter_hash).to eq({ 'status' => ['draft', 'in_review'] })
          end
        end

        context 'datetime filter' do
          subject(:get_index) { json_api_get :index, filter: { published_at: '2020-01-01' } }
          it 'filter is set' do
            get_index

            expect(response).to have_http_status(:ok)
            expect(controller.jsonapi_filter_hash).to eq({ 'published_at' => ['2020-01-01'] })
          end
        end

        context 'boolean filter' do
          subject(:get_index) { json_api_get :index, filter: { subscribers_only: 'True' } }
          it 'filter is set' do
            get_index

            expect(response).to have_http_status(:ok)
            expect(controller.jsonapi_filter_hash).to eq({ 'subscribers_only' => ['True'] })
          end
        end

        context 'ids filter' do
          let(:posts) { create_list(:post, 2) }
          subject(:get_index) { json_api_get :index, filter: { ids: "#{posts.first.id},#{posts.last.id}" } }

          before do
            posts
          end

          it 'filter is set' do
            get_index

            expect(response).to have_http_status(:ok)
            expect(controller.jsonapi_filter_hash).to eq({ 'ids' => [posts.first.id.to_s, posts.last.id.to_s] })
          end
        end
      end

      context 'invalid request' do
        context 'provided filter has invalid structure' do
          subject(:get_index) { json_api_get :index, filter: 'kuku' }

          it 'returns bad_request' do
            get_index

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'filter',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'provided filter key is not allowed' do
          subject(:get_index) { json_api_get :index, filter: { kuku: 'in_review' } }
          it 'returns bad_request' do
            get_index

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'filter[kuku]=in_review',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'provided filter value does not match the allowed values' do
          subject(:get_index) { json_api_get :index, filter: { status: 'kuku' } }

          it 'returns bad_request' do
            get_index

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'filter[status]=kuku',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'provided filter value is not a date' do
          subject(:get_index) { json_api_get :index, filter: { published_at: '2020-kuku' } }

          it 'returns bad_request' do
            get_index

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => '2020-kuku: argument out of range',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end

        context 'provided filter value is not a boolean' do
          subject(:get_index) { json_api_get :index, filter: { subscribers_only: 'kuku' } }

          it 'returns bad_request' do
            get_index

            expect(response).to have_http_status(:bad_request)
            expect(response.body).to eq({ 'errors' => [{
                                                           'title' => 'Invalid Argument',
                                                           'detail' => 'filter[subscribers_only]=kuku',
                                                           'status' => '400'
                                                       }] }.to_json)
          end
        end
      end
    end
  end

  describe 'POST #create' do
    let(:user) { create(:user) }
    subject(:post_create) { json_api_post :create, data: create_json }

    context 'valid' do
      let(:create_json) do
        {
          "type": 'post',
          "attributes": {
            "title": "My first post",
            "text": "And so it begins...",
            "tags": [
              {
                "key": "genre",
                "value": "fiction"
              },
              {
                "key": "region",
                "value": "middle-east"
              }
            ]
          },
          "relationships": {
            "user": {
              "data": { "type": 'user', "id": user.id.to_s }
            },
          }
        }
      end

      it 'returns ok' do
        post_create

        expect(response).to have_http_status(:ok)
      end

      it 'creates tags' do
        expect { post_create }.to change { PostTag.count }.by(2)

        expect(PostTag.first.key).to eq("genre")
        expect(PostTag.first.value).to eq("fiction")
        expect(PostTag.second.key).to eq("region")
        expect(PostTag.second.value).to eq("middle-east")

      end
    end
  end
end
