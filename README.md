# JsonApiable

JsonApiable is an includeable Ruby module that makes it easier for JSON:API Rails controllers to deal with parsing parameters and relationships,
validating arguments, returning well-structured errors, and more - all in a Rails-friendly way.

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
  # before_action :ensure_content_type       - Ensure correct Content-Type (application/vnd.api+json) is set in the request, and return error otherise 
  # before_action :ensure_valid_query_params - Ensure only valid query parameters are used
  # before_action :parse_pagination          - Parse "?page:{number:1, size:25}" query hash, set defaults raise errors when invalid values received
  #                                            Read more: https://jsonapi.org/format/#fetching-pagination 
  # before_action :parse_include             - Parse "?include=posts.author" include directives . 
  #                                             Read more: https://jsonapi.org/format/#fetching-includes
  # after_action :set_content_type           - Ensure correct Content-Type (application/vnd.api+json) is set in the response
  
  # By including JsonApiable, you get the following exceptions handled automatically:
  # rescue_from ArgumentError, with: :respond_to_bad_argument
  # rescue_from ActionController::UnpermittedParameters, with: :respond_to_bad_argument
  # rescue_from MalformedRequestError, with: :respond_to_malformed_request
  # rescue_from UnprocessableEntityError, with: :respond_to_unprocessable_entity
  # rescue_from ActiveRecord::RecordNotFound, with: :respond_to_not_found
  include JsonApiable
end

class API::PostsController < API::BaseController
  
  def index
    # pass page and include info to your logic
    @posts = GetPostsService(jsonapi_page, jsonapi_include)
    # some other gem, such as fast_jsonapi is assumed to produce the json:api output
    render json: collection
  end

  def update
    @user = User.find(params[:id])
    # turn relationships into Rails associations and assign them together with attributes as you would normally do in Rails
    @user.update_attributes!(jsonapi_assign_params)
    render json: @user
  end

  def create
    # exclude 'author' attribute from assign params, for example because it's a separate table on the DB level)
    @author_name = jsonapi_exclude_attribute(:author_name)
    # exclude 'comments' relationship from assign params, for example because we want to filter which ones are added to post
    @comments_hash = jsonapi_exclude_relationship(:comments)
    do_some_logc_with_excluded_params
    # jsonapi_assign_params doesn't include 'author' attribute and 'comments' relationship
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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_apiable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
