class API::PostsController < API::BaseController

  before_action -> { set_jsonapi_filter(API::PostFilter) }, only: %i[index]

  def index
    @posts = Post.all
    render json: @posts
  end

  def show
    @post = Post.find(params[:id])
    render json: @post
  end

  def create
    @post = Post.create!(jsonapi_assign_params)
    render json: @post
  end

  protected

  def jsonapi_allowed_attributes
    [:title,
     :text,
     tags: [:key, :value]]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_relationships
    %i[user]
  end
end
