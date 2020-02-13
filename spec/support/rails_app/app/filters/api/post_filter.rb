# frozen_string_literal: true

class API::PostFilter < JsonApiable::BaseFilter
  def call
    jsonapi_collection.where(status: jsonapi_filter_hash[:status])
  end

  def self.jsonapi_allowed_filters
    {
      status: Post.statuses.keys,
      published_at: datetime_matcher,
      subscribers_only: boolean_matcher,
      ids: ids_matcher(Post)
    }
  end
end
