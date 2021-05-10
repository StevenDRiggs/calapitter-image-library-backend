require 'rails_helper'


include ActiveSupport::Testing::TimeHelpers


RSpec.describe 'User requests', type: :request do
  describe 'POST /login' do
    before(:context) do
      @user = User.create!(username: 'user', email: 'user@email.com', password: 'pass')

      @valid_params = {
        user: {
          usernameOrEmail: 'user',
          password: 'pass',
        }
      }

    end

    after(:context) do
      @user.destroy
      remove_instance_variable(:@valid_params)
    end

    after(:example) do
      @user.update!(flags: {
        'HISTORY' => []
      })
    end

    context 'with valid user params' do
      it 'renders json for user with JWT' do
        travel_to(Time.new(2021, 1, 1))
        post '/login', params: @valid_params
        travel_back

        expect(JSON.parse(response.body)).to include('token', 'user')
        expect(JSON.parse(response.body)['user']).to include('username' => 'user', 'email' => 'user@email.com', 'is_admin' => false)

        expect(JSON.parse(response.body)['user']).to include('flags')
        expect(JSON.parse(response.body)['user']['flags']).to include('HISTORY')
        history_flag = JSON.parse(response.body)['user']['flags']['HISTORY']
        expect(history_flag.length).to be(1)
        expect(history_flag[0][0]).to eq('LAST_LOGIN')
        expect(Time.parse(history_flag[0][1])).to eq(Time.new(2021, 1, 1))
        expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 1, 1))

        expect(JSON.parse(response.body)['user']).to_not include('id', 'password_digest', 'created_at', 'updated_at')
      end

      it 'does not render errors' do
        post '/login', params: @valid_params

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'with invalid user params' do
      before(:context) do
        @invalid_params = {
          user: {
            usernameOrEmail: 'user',
            password: 'pass',
          }
        }
      end

      after(:context) do
        remove_instance_variable(:@invalid_params)
      end

      context 'with invalid username_or_email' do
        before(:context) do
          @invalid_params[:user][:usernameOrEmail] = 'wrong'
        end

        after(:context) do
          @invalid_params[:user][:usernameOrEmail] = 'user'
        end

        it 'does not render json for user' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('user')
        end

        it 'does not return JWT' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('token')
        end

        it 'renders errors' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)['errors']).to include('User not found')
        end
      end

      context 'with invalid password' do
        before(:context) do
          @invalid_params[:user][:password] = 'wrong'
        end

        after(:context) do
          @invalid_params[:user][:password] = 'pass'
        end

        it 'does not render json for user' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('user')
        end

        it 'does not return JWT' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('token')
        end

        it 'renders errors' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)['errors']).to include('User not found')
        end
      end

      context 'when user is BANNED' do
        before(:context) do
          @user.set_flag('BANNED', true)
        end

        after(:context) do
          @user.clear_flag('BANNED')
        end

        it 'does not render json for user' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('user')
        end

        it 'does not return JWT' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to_not include('token')
        end

        it 'renders errors' do
          post '/login', params: @invalid_params

          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)['errors']).to include('User is BANNED')
        end
      end

      context 'when user is SUSPENDED' do
        context 'when SUSPENSION_CLEAR_DATE has passed' do
          before(:example) do
            travel_to(Time.new(2021, 1, 1))

            @user.set_flag('SUSPENDED', true)
            @user.set_flag('SUSPENSION_CLEAR_DATE', Time.now.prev_day)

            travel_back
          end

          it 'clears SUSPENDED and SUSPENSION_CLEAR_DATE flags' do
            post '/login', params: @valid_params

            @user.reload

            expect(@user.flags).to_not include('SUSPENDED', 'SUSPENSION_CLEAR_DATE')
          end

          it 'renders json for user with JWT' do
            travel_to(Time.new(2021, 1, 1))
            post '/login', params: @valid_params
            travel_back

            expect(JSON.parse(response.body)).to include('token', 'user')
            expect(JSON.parse(response.body)['user']).to include('username' => 'user', 'email' => 'user@email.com', 'is_admin' => false)

            expect(JSON.parse(response.body)['user']).to include('flags')
            expect(JSON.parse(response.body)['user']['flags']).to include('HISTORY')
            history_flag = JSON.parse(response.body)['user']['flags']['HISTORY']
            expect(history_flag.length).to be(3)
            
            expect(history_flag[0][0]).to eq('SUSPENDED')
            expect(history_flag[0][1]).to be(true)
            expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 1, 1))

            expect(history_flag[1][0]).to eq('SUSPENSION_CLEAR_DATE')
            expect(Time.parse(history_flag[1][1])).to eq(Time.new(2020, 12, 31))
            expect(Time.parse(history_flag[1][2])).to eq(Time.new(2021, 1, 1))

            expect(history_flag[2][0]).to eq('LAST_LOGIN')
            expect(Time.parse(history_flag[2][1])).to eq(Time.new(2021, 1, 1))
            expect(Time.parse(history_flag[2][2])).to eq(Time.new(2021, 1, 1))

            expect(JSON.parse(response.body)['user']).to_not include('id', 'password_digest', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            travel_to(Time.new(2021, 1, 1))
            post '/login', params: @valid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')
          end
        end

        context 'when SUSPENSION_CLEAR_DATE has not passed' do
          before(:context) do
            travel_to(Time.new(2021, 1, 1))

            @user.set_flag('SUSPENDED', true)
            @user.set_flag('SUSPENSION_CLEAR_DATE', Time.now.next_day)

            travel_back
          end

          it 'does not render json for user' do
            travel_to(Time.new(2021, 1, 1))
            post '/login', params: @invalid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('user')
          end

          it 'does not return JWT' do
            travel_to(Time.new(2021, 1, 1))
            post '/login', params: @invalid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('token')
          end

          it 'renders errors' do
            travel_to(Time.new(2021, 1, 1))
            post '/login', params: @invalid_params
            travel_back

            expect(JSON.parse(response.body)).to include('errors')
            expect(JSON.parse(response.body)['errors']).to include('User is SUSPENDED')
          end
        end
      end
    end
  end

  describe 'GET /users' do
    before(:context) do
      3.times.with_index do |i|
        User.create!(username: "user#{i}", email: "user#{i}@email.com", password: 'pass')
      end
    end

    after(:context) do
      User.destroy_all
    end

    context 'when logged in as admin' do
      before(:example) do
        @user = User.first

        @user.update!(is_admin: true)

        travel_to(Time.new(2021, 1, 1))
        post '/login', params: {
          user: {
            usernameOrEmail: @user.username,
            password: 'pass',
          }
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:example) do
        @user.update!(is_admin: false)
      end

      it 'renders json for all users' do
        get '/users', headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json.length).to be(3)
        resp_json.each.with_index do |user, i|
          expect(user).to include('username' => "user#{i}", 'email' => "user#{i}@email.com", 'is_admin' => (i == 0 ? true : false))
          expect(user).to include('flags')

          expect(user['flags']).to include('HISTORY')
          history_flag = user['flags']['HISTORY']
          if i == 0
            expect(history_flag.length).to be(1)
            expect(history_flag[0][0]).to eq('LAST_LOGIN')
            expect(Time.parse(history_flag[0][1])).to eq(Time.new(2021, 1, 1))
            expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 1, 1))
          else
            expect(history_flag.length).to be(0)
          end
        end
      end

      it 'does not render errors' do
        get '/users', headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'when logged in as non-admin' do
      before(:example) do
        @user = User.last

        travel_to(Time.new(2021, 1, 1))
        post '/login', params: {
          user: {
            usernameOrEmail: @user.username,
            password: 'pass',
          }
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      it 'renders limited json for all users' do
        get '/users', headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json.length).to be(3)
        resp_json.each.with_index do |user, i|
          expect(user).to include('username' => "user#{i}")
          expect(user).to_not include('email', 'is_admin', 'flags')
        end
      end

      it 'does not render errors' do
        get '/users', headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'when not logged in' do
      it 'does not render json for all users' do
        get '/users'

        expect(JSON.parse(response.body)).to_not be_an(Array)
      end

      it 'renders errors' do
        get '/users'

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Must be logged in')
      end
    end
  end

  describe 'GET /users/:id' do
    before(:context) do
      2.times.with_index do |i|
        User.create!(username: "user#{i}", email: "user#{i}@email.com", password: 'pass')
      end

      User.first.update!(is_admin: true)

      @admin_user = User.first
      @non_admin_user = User.last
    end

    after(:context) do
      User.destroy_all
    end

    context 'when logged in as admin' do
      before(:example) do
        travel_to(Time.new(2021, 1, 1))
        post '/login', params: {
          user: {
            usernameOrEmail: @admin_user.username,
            password: 'pass',
          }
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      it 'renders json for user' do
        get "/users/#{@admin_user.id}", headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('user')
        expect(resp_json['user']).to include('username' => @admin_user.username, 'email' => @admin_user.email, 'is_admin' => @admin_user.is_admin)
        expect(resp_json['user']).to include('flags')
        expect(resp_json['user']['flags']).to include('HISTORY')
        user_history = resp_json['user']['flags']['HISTORY']
        expect(user_history.length).to be(1)
        expect(user_history[0][0]).to eq('LAST_LOGIN')
        expect(Time.parse(user_history[0][1])).to eq(Time.new(2021, 1, 1))
        expect(Time.parse(user_history[0][2])).to eq(Time.new(2021, 1, 1))
        expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')

        get "/users/#{@non_admin_user.id}", headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('user')
        expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin)
        expect(resp_json['user']).to include('flags')
        expect(resp_json['user']['flags']).to include('HISTORY')
        user_history = resp_json['user']['flags']['HISTORY']
        expect(user_history.length).to be(0)
        expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
      end

      it 'does not render errors' do
        get "/users/#{@admin_user.id}", headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')

        get "/users/#{@non_admin_user.id}", headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'when logged in as non-admin' do
      context 'when viewing own page' do
        before(:example) do
          travel_to(Time.new(2021, 1, 1))
          post '/login', params: {
            user: {
              usernameOrEmail: @non_admin_user.username,
              password: 'pass',
            }
          }
          travel_back

          @valid_headers = {
            'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
          }
        end

        it 'renders json for user' do
          get "/users/#{@non_admin_user.id}", headers: @valid_headers

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('user')
          expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin)
          expect(resp_json['user']).to include('flags')
          expect(resp_json['user']['flags']).to include('HISTORY')
          user_history = resp_json['user']['flags']['HISTORY']
          expect(user_history.length).to be(1)
          expect(user_history[0][0]).to eq('LAST_LOGIN')
          expect(Time.parse(user_history[0][1])).to eq(Time.new(2021, 1, 1))
          expect(Time.parse(user_history[0][2])).to eq(Time.new(2021, 1, 1))
          expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
        end

        it 'does not render errors' do
          get "/users/#{@non_admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end

      context "when viewing other's page" do
        it 'does not render json for user' do
          get "/users/#{@admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('user')
        end

        it 'renders errors' do
          get "/users/#{@admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to include('errors' => ["Must be logged in as admin to view other's profile"])
        end
      end
    end

    context 'when not logged in' do
      it 'does not render json for user' do
        get "/users/#{@non_admin_user.id}"

        expect(JSON.parse(response.body)).to_not include('user')

        get "/users/#{@admin_user.id}"

        expect(JSON.parse(response.body)).to_not include('user')
      end

      it 'renders errors' do
        get "/users/#{@non_admin_user.id}"

        expect(JSON.parse(response.body)).to include('errors' => ["Must be logged in as admin to view other's profile"])

        get "/users/#{@admin_user.id}"

        expect(JSON.parse(response.body)).to include('errors' => ["Must be logged in as admin to view other's profile"])
      end
    end
  end
  #
  #  describe 'POST /signup' do
  #  end
  #
  #  describe 'PATCH/PUT /users/:id' do
  #  end
  #
  #  describe 'DELETE /users/:id' do
  #  end
end
