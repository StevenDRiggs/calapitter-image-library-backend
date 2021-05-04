class ApplicationController < ActionController::API
  def encode_token(payload)
    JWT.encode(payload, ENV['SECRET_KEY_BASE'], 'HS256')
  end

  def auth_header
    # { Authorization: 'Bearer <token>' }
    request.headers['Authorization']
  end

  def decoded_token
    if auth_header
      token = auth_header.split(' ')[1]
      # header: { Authorization: 'Bearer <token>' }
      begin
        JWT.decode(token, ENV['SECRET_KEY_BASE'], 'HS256')
      rescue JWT::DecodeError => error
        render json: {errors: [error]} and return
      end
    end
  end

  def verify_login
    if decoded_token
      user_id = decoded_token[0]['user_id']
      @user = User.find_by(id: user_id)
    end
  end

  def is_admin?
    verify_login

    render json: {errors: ['Must be logged in as admin']} unless @user && @user.is_admin
  end
end

