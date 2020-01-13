# JsonApiable

JsonApiable is a Ruby module that makes it easier for Rails API controllers to handle JSON:API parameter and relationship parsing,
strong parameter validation, returning well-structured errors and more - all in a Rails-friendly way.

JsonApiable doesn't assume anything about other JSON:API gems you may be using. 
Feel free to use it in conjunction with fast_jsonapi, active_model_serializer, jsonapi-resources or any other library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_apiable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_apiable

## Usage
### Basics
```ruby
# include JsonApiable in your Base API controller
class API::BaseController < ActionController::Base
  # By including JsonApiable, you get the following before/after actions in your controllers:
  # 
  # before_action :ensure_jsonapi_content_type       - Ensure correct Content-Type (application/vnd.api+json) is set in 
  #                                                    the request, and return error othewrise 
  # before_action :ensure_jsonapi_valid_query_params - Ensure only valid query parameters are used
  # before_action :parse_jsonapi_pagination          - Parse "?page:{number:1, size:25}" query hash, set defaults and 
  #                                                    return errors when invalid values received
  #                                                    Read more: https://jsonapi.org/format/#fetching-pagination 
  # before_action :parse_jsonapi_include             - Parse "?include=posts.author" include directives . 
  #                                                    Read more: https://jsonapi.org/format/#fetching-includes
  # after_action :set_jsonapi_content_type           - Ensure correct Content-Type (application/vnd.api+json) is set 
  #                                                    in the response
  
  # By including JsonApiable, you get the following exceptions handled automatically:
  # rescue_from ArgumentError
  # rescue_from ActionController::UnpermittedParameters
  # rescue_from MalformedRequestError
  # rescue_from UnprocessableEntityError
  # rescue_from ActiveRecord::RecordNotFound
  include JsonApiable
end

class API::PostsController < API::BaseController
  
  # GET /v1/posts
  def index
    # pass page and include info to your logic
    posts = GetPostsService.call(jsonapi_page, jsonapi_include)
    # some other gem, such as fast_jsonapi is assumed to produce the json:api output
    render json: posts
  end

  # PATCH /v1/posts/123/update
  # { "data":
  #    { "type": "post",
  #      "attributes": {
  #         "title": "My New Title"
  #      },
  #      "relationships": {
  #         "author": {
  #            "data": {
  #                 "type": "user",
  #                 "id": "4528"
  #            },
  #           "comments": {
  #             "data": [
  #               { "type": "comment", "id": "1489" },
  #               { "type": "comment", "id": "1490" } 
  #             ] 
  #           } 
  #         }
  #        } 
  #     } 
  # }
  def update
    @post = Post.find(params[:id])

    # turn relationships into Rails associations and assign them together with attributes 
    # as you would normally do in Rails
    # 
    # jsonapi_assign_params =>
    # { "title"=>"My New Title",
    #   "author_id" => 4528, 
    #   "comments_attributes"=>{
    #         "0"=>{"id"=>"1489", "_destroy"=>"false"}, 
    #         "1"=>{"id"=>"1490", "_destroy"=>"false"}},
    #   "comment_ids"=>["1489", "1490"],
    # 
    # } 
    @post.update_attributes!(jsonapi_assign_params)
    render json: @user
  end

  def create
    # use jsonapi_attribute_present? to quickly test presence of specific attributes
    raise UnprocessableEntityError, 'No title!' unless jsonapi_attribute_present?(:title)
    # use jsonapi_attribute_value to get attribute values. If non-existent, nil would be returned
    @title = jsonapi_attribute_value(:title)
    # exclude 'author' attribute from assign params, for example because it's a separate table on the DB level)
    @author_name = jsonapi_exclude_attribute(:author_name)
    # exclude 'comments' relationship from assign params, for example because we want to filter which ones are added to post
    @comments_hash = jsonapi_exclude_relationship(:comments)
    do_some_logc_with_excluded_params
    # jsonapi_assign_params wouldn't include 'author' attribute and 'comments' relationship
    User.create!(jsonapi_assign_params)
  end

  protected

  # declare which attributes should be allowed to be assigned. Complex attributes are allowed
  def jsonapi_allowed_attributes
    [:title,
     :body,
     dates: %i[first_drafted published last_edited]]
  end

  # declare which relationships should be allowed to be assigned
  def jsonapi_allowed_relationships
    %i[comments contributors]
  end



end
````
### Configuration
Add an initializer to your app with the following config block:
```ruby
JsonApiable.configure do |config|
  # white-list query params that should be allowed
  config.valid_query_params = %w[ id access_token user_id organization_id ]

  # by default, error is returned if the request Content-Type isn't valid JSON-API. Override the behaviour by using this block:
  config.supported_media_type_proc = proc do |request|
    request.content_type == JsonApiable::JSONAPI_CONTENT_TYPE || request.headers['My-Special-Header'].present?
  end

  # by default, ActiveRecord::RecordNotFound is caught by JsonApiable and turned into an error response. If your backend raises a different class of exception, set it here
  config.not_found_exception_class = MyExceptionClass

end
```

### Limitations
- `has_one` associations are currently not supported by `jsonapi_assign_params`. So if the updated resource
contains an association whose foreign key exists in
- complex attributes currently don't work

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_apiable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
