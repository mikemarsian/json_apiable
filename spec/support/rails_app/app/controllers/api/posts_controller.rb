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
end
