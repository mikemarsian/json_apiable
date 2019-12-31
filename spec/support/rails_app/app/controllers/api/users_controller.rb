class API::UsersController < API::BaseController
  def index
    @users = User.all
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: @user
  end

  def update
    @user = User.find(params[:id])
    @user.update_attributes!(jsonapi_assign_params)
    render json: @user
  end

  protected

  def jsonapi_allowed_attributes
    [:email, :name, address: %i[street city state_code zip_code country_code]]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_relationships
    %w[posts]
  end
end
