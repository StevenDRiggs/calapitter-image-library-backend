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
        travel_to(Time.new(2021, 2, 2))
        post '/login', params: @valid_params
        travel_back

        expect(JSON.parse(response.body)).to include('token', 'user')
        expect(JSON.parse(response.body)['user']).to include('username' => 'user', 'email' => 'user@email.com', 'is_admin' => false)

        expect(JSON.parse(response.body)['user']).to include('flags')
        expect(JSON.parse(response.body)['user']['flags']).to include('HISTORY')
        history_flag = JSON.parse(response.body)['user']['flags']['HISTORY']
        expect(history_flag.length).to be(1)
        expect(history_flag[0][0]).to eq('LAST_LOGIN')
        expect(Time.parse(history_flag[0][1])).to eq(Time.new(2021, 2, 2))
        expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 2, 2))

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
            travel_to(Time.new(2021, 2, 2))

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
            travel_to(Time.new(2021, 2, 2))
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
            expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 2, 2))

            expect(history_flag[1][0]).to eq('SUSPENSION_CLEAR_DATE')
            expect(Time.parse(history_flag[1][1])).to eq(Time.new(2021, 2, 1))
            expect(Time.parse(history_flag[1][2])).to eq(Time.new(2021, 2, 2))

            expect(history_flag[2][0]).to eq('LAST_LOGIN')
            expect(Time.parse(history_flag[2][1])).to eq(Time.new(2021, 2, 2))
            expect(Time.parse(history_flag[2][2])).to eq(Time.new(2021, 2, 2))

            expect(JSON.parse(response.body)['user']).to_not include('id', 'password_digest', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            travel_to(Time.new(2021, 2, 2))
            post '/login', params: @valid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')
          end
        end

        context 'when SUSPENSION_CLEAR_DATE has not passed' do
          before(:context) do
            travel_to(Time.new(2021, 2, 2))

            @user.set_flag('SUSPENDED', true)
            @user.set_flag('SUSPENSION_CLEAR_DATE', Time.now.next_day)

            travel_back
          end

          it 'does not render json for user' do
            travel_to(Time.new(2021, 2, 2))
            post '/login', params: @invalid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('user')
          end

          it 'does not return JWT' do
            travel_to(Time.new(2021, 2, 2))
            post '/login', params: @invalid_params
            travel_back

            expect(JSON.parse(response.body)).to_not include('token')
          end

          it 'renders errors' do
            travel_to(Time.new(2021, 2, 2))
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

        travel_to(Time.new(2021, 2, 2))
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
            expect(Time.parse(history_flag[0][1])).to eq(Time.new(2021, 2, 2))
            expect(Time.parse(history_flag[0][2])).to eq(Time.new(2021, 2, 2))
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

        travel_to(Time.new(2021, 2, 2))
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
        travel_to(Time.new(2021, 2, 2))
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
        expect(Time.parse(user_history[0][1])).to eq(Time.new(2021, 2, 2))
        expect(Time.parse(user_history[0][2])).to eq(Time.new(2021, 2, 2))
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
          travel_to(Time.new(2021, 2, 2))
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
          expect(Time.parse(user_history[0][1])).to eq(Time.new(2021, 2, 2))
          expect(Time.parse(user_history[0][2])).to eq(Time.new(2021, 2, 2))
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

  describe 'POST /signup' do
    context 'with valid params' do
      let(:valid_params) {
        {
          user: {
            username: 'new user',
            email: 'new@user.com',
            password: 'pass',
          }
        }
      }

      it 'creates new user' do
        expect {
          post '/signup', params: valid_params
        }.to change {
          User.all.length
        }.by(1)
      end

      it 'renders json for new user with JWT' do
        travel_to(Time.new(2021, 2, 2))
        post '/signup', params: valid_params
        travel_back

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('user', 'token')
        expect(resp_json['user']).to include('username' => valid_params[:user][:username], 'email' => valid_params[:user][:email], 'is_admin' => false)
        expect(resp_json['user']).to include('flags')
        expect(resp_json['user']['flags']).to include('HISTORY')
        user_history = resp_json['user']['flags']['HISTORY']
        expect(user_history.length).to be(1)
        expect(user_history[0][0]).to eq('LAST_LOGIN')
        expect(Time.parse(user_history[0][1])).to eq(Time.new(2021, 2, 2))
        expect(Time.parse(user_history[0][2])).to eq(Time.new(2021, 2, 2))
        expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
      end

      it 'does not render errors' do
        post '/signup', params: valid_params

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) {
        {
          user: {
            username: '',
            email: '',
            password: '',
          }
        }
      }

      it 'does not create new user' do
        expect {
          post '/signup', params: invalid_params
        }.to_not change {
          User.all.length
        }
      end

      it 'does not render json for user with JWT' do
        post '/signup', params: invalid_params

        expect(JSON.parse(response.body)).to_not include('user', 'token')
      end

      it 'renders errors' do
        post '/signup', params: invalid_params

        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end

  describe 'PATCH/PUT /users/:id' do
    before(:context) do
      travel_to(Time.new(2021, 1, 1))
      @admin_user = User.create!(username: 'old admin', email: 'old@admin.com', password: 'old admin pass', is_admin: true)
      @non_admin_user = User.create!(username: 'old non-admin', email: 'old@nonadmin.com', password: 'old non-admin pass')
      travel_back
    end

    after(:context) do
      @admin_user.destroy
      @non_admin_user.destroy
    end

    context 'when logged in as admin' do
      before(:context) do
        travel_to(Time.new(2021, 2, 2))
        post '/login', params: {
          user: {
            usernameOrEmail: @admin_user.username,
            password: 'old admin pass',
          }
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when updating own profile' do
        context 'when updating username, email, password' do
          let(:update_params) {
            {
              username: 'new username',
              email: 'new@email.com',
              password: 'new pass',
            }
          }

          it 'updates user profile' do
            expect {
              travel_to(Time.new(2021, 2, 2))
              patch "/users/#{@admin_user.id}", params: {
                user: {
                  **update_params,
                },
              }, headers: @valid_headers
              travel_back

              @admin_user.reload
            }.to change {
              @admin_user.password_digest
            }

            expect(@admin_user.username).to eq('new username')
            expect(@admin_user.email).to eq('new@email.com')
            expect(@admin_user.updated_at).to eq(Time.new(2021, 2, 2))
          end

          it 'renders json for updated user' do
            patch "/users/#{@admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @admin_user.username, 'email' => @admin_user.email, 'is_admin' => @admin_user.is_admin, 'flags' => @admin_user.flags)
            expect(resp_json).to_not include('id', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            patch "/users/#{@admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @admin_user.reload

            expect(JSON.parse(response.body)['user']).to_not include('errors')
          end
        end

        context 'when updating flags through set_flag or clear_flag' do
          it 'updates user profile' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                setFlags: [['TEST_FLAG', true]],
              },
            }, headers: @valid_headers
            travel_back

            @admin_user.reload

            expect(@admin_user.flags).to include('TEST_FLAG' => 'true')
            expect(@admin_user.flags).to include('HISTORY')
            user_history = @admin_user.flags['HISTORY']
            expect(user_history.map {|entry| entry[0]}).to include('LAST_LOGIN', 'TEST_FLAG')
            expect(user_history.map {|entry| Time.parse(entry[2])}).to all(eq(Time.new(2021, 2, 2)))

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                clearFlags: ['TEST_FLAG'],
              },
            }, headers: @valid_headers
            travel_back

            @admin_user.reload

            expect(@admin_user.flags).to_not include('TEST_FLAG')
            expect(@admin_user.flags).to include('HISTORY')
            user_history = @admin_user.flags['HISTORY']
            expect(user_history.map {|entry| entry[0]}).to include('LAST_LOGIN', 'TEST_FLAG')
          end

          it 'renders json for updated user' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                setFlags: [['TEST_FLAG', true]],
              },
            }, headers: @valid_headers
            travel_back

            @admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @admin_user.username, 'email' => @admin_user.email, 'is_admin' => @admin_user.is_admin, 'flags' => @admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                clearFlags: ['TEST_FLAG'],
              },
            }, headers: @valid_headers
            travel_back

            @admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @admin_user.username, 'email' => @admin_user.email, 'is_admin' => @admin_user.is_admin, 'flags' => @admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                setFlags: [['TEST_FLAG', true]],
              },
            }, headers: @valid_headers
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                clearFlags: ['TEST_FLAG'],
              },
            }, headers: @valid_headers
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')
          end

          it 'does not allow modifying flags directly' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@admin_user.id}", params: {
              user: {
                flags: ['TEST_FLAG', true],
              },
            }, headers: @valid_headers

            @admin_user.reload

            expect(@admin_user.flags).to_not include('TEST_FLAG')
          end
        end

        context 'when updating id, created_at, updated_at, or is_admin directly' do
          let(:update_params) {
            {
              id: 9999,
              created_at: Time.new(2015, 9, 17),
              updated_at: Time.new(2016, 1, 17),
              is_admin: false,
            }
          }

          it 'does not update user profile' do
            user_attrs = @admin_user.attributes.except('updated_at', 'flags')

            patch "/users/#{@admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @admin_user.reload

            expect(@admin_user.attributes.except('updated_at', 'flags')).to eq(user_attrs)
            expect(@admin_user.updated_at).to eq(Time.new(2021, 2, 2))
          end

          it 'renders json for non-updated user' do
            patch "/users/#{@admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @admin_user.username, 'email' => @admin_user.email, 'is_admin' => @admin_user.is_admin, 'flags' => @admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end
        end
      end

      context "when updating other's profile" do
        context 'when updating username, email, password' do
          let(:update_params) {
            {
              username: 'new username',
              email: 'new@email.com',
              password: 'new password',
            }
          }

          it 'does not update user profile' do
            user_attrs = @non_admin_user.attributes

            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            expect(@non_admin_user.attributes).to eq(user_attrs)
          end

          it 'renders json for non-updated user' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end

          it 'renders errors' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('errors')
            expect(resp_json['errors']).to include('Update action forbidden')
          end
        end

        context 'when updating flags via set_flag or clear_flag' do
          let(:setFlags) {
            {
              setFlags: [['TEST_FLAG', true]],
            }
          }

          let(:clearFlags) {
            {
              clearFlags: ['TEST_FLAG'],
            }
          }

          it 'updates user profile' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **setFlags,
              },
            }, headers: @valid_headers
            travel_back

            @non_admin_user.reload

            expect(@non_admin_user.flags).to include('TEST_FLAG' => 'true')
            expect(@non_admin_user.flags).to include('HISTORY')
            user_history = @non_admin_user.flags['HISTORY']
            expect(user_history.map {|entry| entry[0]}).to include('TEST_FLAG')
            expect(user_history.map {|entry| Time.parse(entry[2])}).to all(eq(Time.new(2021, 2, 2)))

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **clearFlags,
              },
            }, headers: @valid_headers
            travel_back

            @non_admin_user.reload

            expect(@non_admin_user.flags).to_not include('TEST_FLAG')
            expect(@non_admin_user.flags).to include('HISTORY')
            user_history = @non_admin_user.flags['HISTORY']
            expect(user_history.map {|entry| entry[0]}).to include('TEST_FLAG')
          end

          it 'renders json for updated user' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **setFlags,
              },
            }, headers: @valid_headers
            travel_back

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **clearFlags,
              },
            }, headers: @valid_headers
            travel_back

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **setFlags,
              },
            }, headers: @valid_headers
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')

            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **clearFlags,
              },
            }, headers: @valid_headers
            travel_back

            expect(JSON.parse(response.body)).to_not include('errors')
          end

          it 'does not allow modifying flags directly' do
            travel_to(Time.new(2021, 2, 2))
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                flags: ['TEST_FLAG', true],
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            expect(@non_admin_user.flags).to_not include('TEST_FLAG')
          end
        end

        context 'when updating id, created_at, updated_at, or is_admin directly' do
          let(:update_params) {
            {
              id: 9999,
              created_at: Time.new(2015, 9, 17),
              updated_at: Time.new(2016, 1, 17),
              is_admin: false,
            }
          }

          it 'does not update user profile' do
            user_attrs = @non_admin_user.attributes

            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            expect(@non_admin_user.attributes).to eq(user_attrs)
          end

          it 'renders json for non-updated user' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end
        end
      end
    end

    context 'when logged in as non-admin' do
      before(:context) do
        travel_to(Time.new(2021, 2, 2))
        post '/login', params: {
          user: {
            usernameOrEmail: @non_admin_user.username,
            password: 'old non-admin pass',
          }
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when updating own profile' do
        context 'when updating username, email, password' do
          let(:update_params) {
            {
              username: 'new username',
              email: 'new@email.com',
              password: 'new pass',
            }
          }

          it 'updates user profile' do
            expect {
              travel_to(Time.new(2021, 2, 2))
              patch "/users/#{@non_admin_user.id}", params: {
                user: {
                  **update_params,
                },
              }, headers: @valid_headers
              travel_back

              @non_admin_user.reload
            }.to change {
              @non_admin_user.password_digest
            }

            expect(@non_admin_user.username).to eq('new username')
            expect(@non_admin_user.email).to eq('new@email.com')
            expect(@non_admin_user.updated_at).to eq(Time.new(2021, 2, 2))
          end

          it 'renders json for updated user' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json).to_not include('id', 'created_at', 'updated_at')
          end

          it 'does not render errors' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params,
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            expect(JSON.parse(response.body)['user']).to_not include('errors')
          end
        end

        context 'when updating flags via set_flag or clear_flag' do
          let(:setFlags) {
            {
              user: {
                setFlags: [['TEST_FLAG', true]],
              },
            }
          }

          let(:clearFlags) {
            {
              user: {
                clearFlags: ['TEST_FLAG'],
              },
            }
          }

          it 'does not update user profile' do
            expect {
              patch "/users/#{@non_admin_user.id}", params: setFlags, headers: @valid_headers

              @non_admin_user.reload
            }.to_not change {
              @non_admin_user
            }

            expect {
              patch "/users/#{@non_admin_user.id}", params: clearFlags, headers: @valid_headers

              @non_admin_user.reload
            }.to_not change {
              @non_admin_user
            }
          end

          it 'renders json for non-updated user' do
            patch "/users/#{@non_admin_user.id}", params: setFlags, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')

            patch "/users/#{@non_admin_user.id}", params: clearFlags, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end

          it 'renders errors' do
            patch "/users/#{@non_admin_user.id}", params: setFlags, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('errors')
            expect(resp_json['errors']).to include('Update action forbidden')

            patch "/users/#{@non_admin_user.id}", params: clearFlags, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('errors')
            expect(resp_json['errors']).to include('Update action forbidden')
          end
        end

        context 'when updating id, created_at, updated_at, or is_admin directly' do
          let(:update_params) {
            {
              id: 9999,
              created_at: Time.new(2015, 9, 17),
              updated_at: Time.new(2016, 1, 17),
              is_admin: false,
            }
          }

          it 'does not update user profile' do
            user_attrs = @non_admin_user.attributes.except('updated_at', 'flags')

            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            expect(@non_admin_user.attributes.except('updated_at', 'flags')).to eq(user_attrs)
            expect(@non_admin_user.updated_at).to eq(Time.new(2021, 2, 2))
          end

          it 'renders json for non-updated user' do
            patch "/users/#{@non_admin_user.id}", params: {
              user: {
                **update_params
              },
            }, headers: @valid_headers

            @non_admin_user.reload

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('user')
            expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
            expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
          end
        end

        context "when updating other's profile" do
          let(:update_params) {
            {
              user: {
                username: 'new username',
                email: 'new@email.com',
                password: 'new pass',
                setFlags: [['TEST_FLAG', true]],
              }
            }
          }

          it 'does not update user profile' do
            expect {
              patch "/users/#{@admin_user.id}", params: update_params, headers: @valid_headers

              @admin_user.reload
            }.to_not change {
              @admin_user
            }
          end

          it 'does not render json for user' do
            patch "/users/#{@admin_user.id}", params: update_params, headers: @valid_headers

            expect(JSON.parse(response.body)).to_not include('user')
          end

          it 'renders errors' do
            patch "/users/#{@admin_user.id}", params: update_params, headers: @valid_headers

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('errors')
            expect(resp_json['errors']).to include('Update action forbidden')
          end
        end
      end
    end

    context 'when not logged in' do
      let(:update_params) {
        {
          user: {
            username: 'new username',
            email: 'new@email.com',
            password: 'new pass',
            setFlags: [['TEST_FLAG', true]],
          }
        }
      }

      it 'does not update user profile' do
        expect {
          patch "/users/#{@admin_user.id}", params: update_params

          @admin_user.reload
        }.to_not change {
          @admin_user
        }
      end

      it 'does not render json for user' do
        patch "/users/#{@admin_user.id}", params: update_params

        expect(JSON.parse(response.body)).to_not include('user')
      end

      it 'renders errors' do
        patch "/users/#{@admin_user.id}", params: update_params

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Update action forbidden')
      end
    end
  end

  describe 'DELETE /users/:id' do
    before(:context) do
      travel_to(Time.new(2021, 1, 1))
      @admin_user = User.create!(username: 'admin user', email: 'admin@email.com', password: 'pass', is_admin: true)
      @non_admin_user = User.create!(username: 'non-admin user', email: 'nonadmin@email.com', password: 'pass')
      travel_back
    end

    after(:context) do
      @admin_user ? @admin_user.destroy : nil
      @non_admin_user ? @non_admin_user.destroy : nil
    end

    context 'when logged in as admin' do
      before(:context) do
        travel_to(Time.new(2021, 2, 2))
        post '/login', params: {
          user: {
            usernameOrEmail: @admin_user.username,
            password: 'pass',
          },
        }
        travel_back

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when user is not flagged for DELETE' do
        before(:example) do
          @admin_user.reload
          @non_admin_user.reload
        end

        after(:example) do
          @admin_user.clear_flag('DELETE')
          @non_admin_user.clear_flag('DELETE')
        end

        it 'does not delete user' do
          expect {
            delete "/users/#{@non_admin_user.id}", headers: @valid_headers
          }.to_not change {
            User.all.length
          }
        end

        it 'flags user for DELETE' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          @non_admin_user.reload

          expect(@non_admin_user.flags).to include('DELETE' => @admin_user.username)
        end

        it 'renders json for updated user' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          @non_admin_user.reload

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('user')
          expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
        end

        it 'does not render errors' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end

      context 'when user is flagged for delete' do
        before(:example) do
          @non_admin_user.set_flag('DELETE', @admin_user.username)
        end

        it 'deletes user' do
          expect {
            delete "/users/#{@non_admin_user.id}", headers: @valid_headers
          }.to change {
            User.all.length
          }.by(-1)
        end

        it 'renders json success message' do
          delete_username = @non_admin_user.username

          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to include('user' => "#{delete_username} DELETED")
        end

        it 'does not render errors' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end
    end

    context 'when logged in as non-admin' do
      before(:context) do
        post '/login', params: {
          user: {
            usernameOrEmail: @non_admin_user.username,
            password: 'pass',
          },
        }

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when requesting DELETE own account' do
        it 'does not delete user' do
          expect {
            delete "/users/#{@non_admin_user.id}", headers: @valid_headers
          }.to_not change {
            User.all.length
          }
        end

        it 'flags user for DELETE' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          @non_admin_user.reload

          expect(@non_admin_user.flags).to include('DELETE' => @non_admin_user.username)
        end

        it 'renders json for updated user' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          @non_admin_user.reload

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('user')
          expect(resp_json['user']).to include('username' => @non_admin_user.username, 'email' => @non_admin_user.email, 'is_admin' => @non_admin_user.is_admin, 'flags' => @non_admin_user.flags)
          expect(resp_json['user']).to_not include('id', 'created_at', 'updated_at')
        end

        it 'does not render errors' do
          delete "/users/#{@non_admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end

      context 'when requesting DELETE other account' do
        it 'does not delete user' do
          expect {
            delete "/users/#{@admin_user.id}", headers: @valid_headers
          }.to_not change {
            User.all.length
          }
        end

        it 'does not flag user for DELETE' do
          expect {
            delete "/users/#{@admin_user.id}", headers: @valid_headers
          }.to_not change {
            @admin_user.flags
          }
        end

        it 'does not render json success message' do
          delete "/users/#{@admin_user.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('user')
        end

        it 'renders errors' do
          delete "/users/#{@admin_user.id}", headers: @valid_headers

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('errors')
          expect(resp_json['errors']).to include('Delete action forbidden')
        end
      end
    end

    context 'when not logged in' do
      it 'does not delete user' do
        expect {
          delete "/users/#{@admin_user.id}"
        }.to_not change {
          User.all.length
        }
      end

      it 'does not flag user for DELETE' do
        expect {
          delete "/users/#{@admin_user.id}"
        }.to_not change {
          @admin_user.flags
        }
      end

      it 'does not render json success message' do
        delete "/users/#{@admin_user.id}"

        expect(JSON.parse(response.body)).to_not include('user')
      end

      it 'renders errors' do
        delete "/users/#{@admin_user.id}"

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Delete action forbidden')
      end
    end
  end
end
