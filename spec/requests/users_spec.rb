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

    context 'with valid user params' do
      it 'renders json for user with JWT' do
        post '/login', params: @valid_params

        expect(JSON.parse(response.body)).to include('token', 'user')
        expect(JSON.parse(response.body)['user']).to include('username' => 'user', 'email' => 'user@email.com', 'is_admin' => false, 'flags' => {'HISTORY' => []})
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
        before(:context) do
          travel_to(Time.new(2021, 1, 1))

          @user.set_flag('SUSPENDED', true)

          travel_back
        end

        context 'when SUSPENSION_CLEAR_DATE has passed' do
          before(:example) do
            travel_to(Time.new(2021, 1, 1))

            @user.set_flag('SUSPENSION_CLEAR_DATE', Time.now.prev_day)

            travel_back
          end

          it 'clears SUSPENDED and SUSPENSION_CLEAR_DATE flags' do
            post '/login', params: @valid_params

            @user.reload

            expect(@user.flags).to_not include('SUSPENDED', 'SUSPENSION_CLEAR_DATE')
          end

          it 'renders json for user with JWT' do
            post '/login', params: @valid_params

            expect(JSON.parse(response.body)).to include('token', 'user')
            expect(JSON.parse(response.body)['user']).to include('username' => 'user', 'email' => 'user@email.com', 'is_admin' => false)
            expect(JSON.parse(response.body)['user']).to include('flags')
            expect(JSON.parse(response.body)['user']['flags']).to include('HISTORY')

            hist = JSON.parse(response.body)['user']['flags']['HISTORY']
            expect(hist[-3]).to include('SUSPENDED')
            expect(hist[-2]).to include('SUSPENSION_CLEAR_DATE')

            susp = hist[-3]['SUSPENDED']
            expect(susp[0]).to be(true)
            expect(Time.parse(susp[1])).to eq(Time.new(2021, 1, 1))

            scd = hist[-2]['SUSPENSION_CLEAR_DATE']
            expect(Time.parse(scd[0])).to eq(Time.new(2020, 12, 31))
            expect(Time.parse(scd[1])).to eq(Time.new(2021, 1, 1))

            expect(JSON.parse(response.body)['user']).to_not include('id', 'password_digest', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            post '/login', params: @valid_params

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

    #  describe 'GET /users' do
    #    context 'when logged in as admin' do
    #      it 'succeeds' do
    #      end
    #
    #      it 'renders json for all users' do
    #      end
    #
    #      it 'does not render errors' do
    #      end
    #    end
    #
    #    context 'when logged in as non-admin' do
    #      it 'succeeds' do
    #      end
    #
    #      it 'renders limited json for all users' do
    #      end
    #
    #      it 'does not render errors' do
    #      end
    #    end
    #
    #    context 'when not logged in' do
    #      it 'is forbidden' do
    #      end
    #
    #      it 'does not render json for all users' do
    #      end
    #
    #      it 'renders errors' do
    #      end
    #    end
    #  end
    #
    #  describe 'GET /users/:id' do
    #  end
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
