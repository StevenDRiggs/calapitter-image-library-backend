require 'rails_helper'
require 'user'


RSpec.describe User do
  context 'with valid params' do
    let(:valid_params) {
      {
        username: 'user',
        email: 'user@email.com',
        password: 'pass',
      }
    }

    it 'creates new user' do
      expect {
        User.create!(valid_params)
      }.to change {
        User.all.length
      }.by(1)
    end

    it 'updates existing user' do
      user = User.create!(username: 'other user', email: 'other@user.com', password: 'other pass')

      expect {
        user.update!(valid_params)
      }.to change {
        user.username
      }.and change {
        user.email
      }.and change {
        user.password_digest
      }
    end
  end

  context 'with invalid params' do
    before(:context) do
      @invalid_params = {
        username: 'user',
        email: 'user@email.com',
        password: 'pass',
      }
    end

    after(:context) do
      remove_instance_variable(:@invalid_params)
    end

    context 'when validating username' do
      context 'with blank username' do
        before(:example) do
          @invalid_params[:username] = ''
        end

        after(:example) do
          @invalid_params[:username] = 'user'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end

      context 'with username too short' do
        before(:example) do
          @invalid_params[:username] = '1'
        end

        after(:example) do
          @invalid_params[:username] = 'user'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end

      context 'with profane username' do
        before(:example) do
          @invalid_params[:username] = ['bitch', 'b1tch'].sample
        end

        after(:example) do
          @invalid_params[:username] = 'user'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end
    end

    context 'when validating email' do
      context 'with blank email' do
        before(:example) do
          @invalid_params[:email] = ''
        end

        after(:example) do
          @invalid_params[:email] = 'user@email.com'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end

      context 'with invalid email' do
        before(:example) do
          @invalid_params[:email] = 'notanemail'
        end

        after(:example) do
          @invalid_params[:email] = 'user@email.com'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end

      context 'with profane email' do
        before(:example) do
          @invalid_params[:email] = ['bitch@email.com', 'b1tch@email.com'].sample
        end

        after(:example) do
          @invalid_params[:email] = 'user@email.com'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end
    end

    context 'when validating password' do
      context 'with password too short' do
        before(:example) do
          @invalid_params[:password] = '1'
        end

        after(:example) do
          @invalid_params[:password] = 'pass'
        end

        it 'does not create new user' do
          expect {
            User.create(@invalid_params)
          }.to_not change {
            User.all.length
          }
        end

        it 'does not update existing user' do
          user = User.create!(username: 'valid username', email: 'valid@email.com', password: 'pass')

          expect(user.update(@invalid_params)).to be(false)
        end
      end
    end
  end
end
