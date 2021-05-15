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
    @name = jsonapi_attribute(:name)
    @email = jsonapi_attribute(:email)

    if params[:exclude_after_assign]
      # jsonapi_assign_params called first time
      jsonapi_assign_params
      jsonapi_exclude_attribute(:email)
      # jsonapi_assign_params called second time
      @user.update!(jsonapi_assign_params)
    else
      @user.update!(jsonapi_assign_params)
    end

    render json: @user
  end

  protected

  def jsonapi_allowed_attributes
    [:email,
     :name,
     address: %i[street city state_code zip_code country_code]]
  end

  # Should be overwritten in specific controllers
  def jsonapi_allowed_relationships
    %i[posts]
  end
end
