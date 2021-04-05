class UsersController < ApplicationController
  before_action :set_user, only: [:show, :destroy]

  #RESTful routes

  # GET /users
  def index
    @users = User.all

    render json: @users
  end

  # GET /users/:id
  def show
    render json: @user
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    #colors = %w(red orange yellow green blue indigo violet)
    #color = colors.sample

    #@user.avatar.attach(io: File.open("avatar_svgs/#{color}.svg"), filename: "#{color}.svg")
    @user.avatar.attach(io: File.open("Steven_Riggs_photo.jpg"), filename: "Steven_Riggs_photo.jpg")

    if @user.save
      token = encode_token({user_id: @user.id})
      session[:user_id] = @user.id
      render json: {
        user: {
          username: @user.username,
          email: @user.email,
          is_admin: @user.is_admin,
          avatar: @user.avatar.download,
        },
        token: token,
      }, status: :created, location: @user
    else
      render json: {
        errors: @user.errors.full_messages, status: :unprocessable_entity,
      }
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: {
        errors: @user.errors.full_messages, status: :unprocessable_entity,
      }
    end
  end

  # DELETE /users/:id
  def destroy
    @user.destroy
  end


  # non-RESTful routes
  def login
    username_or_email, password = user_params.values_at(:usernameOrEmail, :password)

    @user = User.find_by_username_or_email(username_or_email)
    unless @user && @user.authenticate(password)
      render json: {
        errors: @user.errors.full_messages, status: :unprocessable_entity,
      } and return
    end

    token = encode_token({user_id: @user.id})
    session[:user_id] = @user.id

    render json: {
      user: {
        username: @user.username,
        email: @user.email,
        is_admin: @user.is_admin,
        avatar: @user.avatar.download,
      },
      token: token,
    }, content_type: 'multipart/formdata'
  end

  def logout
    session.clear

    render json: 'Session cleared'
  end


  # processing methods

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(session[:user_id])
  end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit([:username, :email, :password, :usernameOrEmail])
  end

  #def auto_login
  #end
end
