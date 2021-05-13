class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]

  #RESTful routes

  # GET /users
  def index
    @users = User.all.sort {|a, b| a.id <=> b.id}

    if is_admin?
      render json: @users and return
    elsif verify_login
      render json: @users.map {|user|
        {
          'username' => user.username,
        }
      }
    else
      render json: {
        errors: ['Must be logged in'],
      }
    end
  end

  # GET /users/:id
  def show
    if is_admin? || (@user && @user.id == params[:id].to_i)
      begin
        render json: {
          user: User.find(params[:id]),
        }
      rescue ActiveRecord::RecordNotFound
        render json: {
          errors: ['User not found'],
        } and return
      end
    else
      render json: {
        errors: ["Must be logged in as admin to view other's profile"],
      }
    end
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    #colors = %w(red orange yellow green blue indigo violet)
    #color = colors.sample

    #@user.avatar.attach(io: File.open("avatar_svgs/#{color}.svg"), filename: "#{color}.svg")
    #@user.avatar.attach(io: File.open("Steven_Riggs_photo.jpg"), filename: "Steven_Riggs_photo.jpg")

    if @user.save
      @user.set_flag('LAST_LOGIN', Time.now)
      @user.clear_flag('LAST_LOGIN')

      token = encode_token({user_id: @user.id})

      render json: {
        user: @user,
        token: token,
      }, status: :created, location: @user
    else
      render json: {
        errors: @user.errors.full_messages, status: :unprocessable_entity,
      }
    end
  end

  # PATCH/PUT /users/:id
  def update
    @output = {
      user: nil,
      errors: nil,
    }

    @u_p = user_params.to_h

    begin
      update_user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound => error
      @output[:errors] = error
    end

    if @u_p.include?('username') || @u_p.include?('email') || @u_p.include?('password')
      @output[:errors] = (@output[:errors] ? @output[:errors] + ['Update action forbidden'] : ['Update action forbidden']) unless @user == update_user
    end

    if @u_p.include?('setFlags')
      @output[:errors] = @output[:errors] ? @output[:errors] + ['Update action forbidden'] : ['Update action forbidden'] unless is_admin?

      # NOTE: this may break when GitHub issue #23640 is fixed
      for i in (0...@u_p[:setFlags].length).step(2) do
        update_user.set_flag_no_update(@u_p[:setFlags][i], @u_p[:setFlags][i + 1])
      end

      @u_p = @u_p.except(:setFlags)
    end

    if @u_p && @u_p.include?('clearFlags')
      @output[:errors] = @output[:errors] ? @output[:errors] + ['Update action forbidden'] : ['Update action forbidden'] unless is_admin?

      @u_p[:clearFlags].each do |flag|
        update_user.clear_flag_no_update(flag)
      end

      @u_p = @u_p.except(:clearFlags)
    end

    if (@output[:errors].nil? || !@output[:errors].include?('Update action forbidden')) && ((!@u_p.empty? && update_user.update(@u_p)) || (update_user.has_changes_to_save? && update_user.save))
        @output[:user] = update_user
    else
      if is_admin? || @user == update_user
        @output[:user] = User.find(params[:id])
        @output[:errors] = @output[:errors] ? @output[:errors] + update_user.errors.full_messages : update_user.errors.full_messages
      else
        @output[:errors] = ['Update action forbidden']
      end
    end

    render json: @output.reject {|key, value| value.nil?}
  end

  # DELETE /users/:id
  def destroy
    @user.destroy
  end


  # non-RESTful routes
  # POST /login
  def login
    username_or_email, password = user_params.values_at(:usernameOrEmail, :password)

    @user = User.find_by_username_or_email(username_or_email)
    unless @user && @user.authenticate(password)
      render json: {
        errors: ['User not found'], status: :unprocessable_entity,
      } and return
    else
      if @user.flags['BANNED']
        render json: {
          errors: ['User is BANNED'], status: :forbidden,
        } and return
      elsif @user.flags['SUSPENDED']
        if Time.now < Time.parse(@user.flags['SUSPENSION_CLEAR_DATE'])
          render json: {
            errors: ['User is SUSPENDED'], status: :forbidden,
          } and return
        else
          @user.clear_flag('SUSPENDED')
          @user.clear_flag('SUSPENSION_CLEAR_DATE')
        end
      end
    end

    token = encode_token({user_id: @user.id})

    @user.set_flag('LAST_LOGIN', Time.now)
    @user.clear_flag('LAST_LOGIN')

    render json: {
      user: @user,
      token: token,
    }, content_type: 'multipart/formdata'
  end


  # processing methods

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = verify_login
  end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit([:username, :email, :password, :usernameOrEmail, setFlags: [], clearFlags: []])
  end
end
