require 'rails_helper'
require 'active_support/testing/time_helpers'

require 'user'


include ActiveSupport::Testing::TimeHelpers


RSpec.describe User do
  context 'class methods' do
    context 'self.find_by_username_or_email' do
      let(:user) {
        User.create!(username: 'user', email: 'user@email.com', password: 'pass')
      }

      it 'returns user based on username' do
        user

        expect(User.find_by_username_or_email('user')).to eq(user)
      end

      it 'returns user based on email' do
        user

        expect(User.find_by_username_or_email('user@email.com')).to eq(user)
      end
    end
  end

  context 'instance methods' do
    before(:context) do
      @user = User.create!(username: 'user', email: 'user@email.com', password: 'pass')
    end

    after(:context) do
      @user.destroy
    end

    context 'set_flag' do
      before(:example) do
        travel_to(Time.new(2021, 1, 1))

        @user.set_flag('TEST_FLAG', true)
      end

      after(:example) do
        travel_back
      end

      it 'sets the flag' do
        @user.reload

        expect(@user.flags).to include('TEST_FLAG' => true)
      end

      fit 'updates HISTORY' do
        @user.reload

        expect(@user.flags['HISTORY'].last).to eq('TEST_FLAG' => [true, Time.now.to_s])
      end
    end

    context 'clear_flag' do
      it 'clears the flag' do
      end
    end
  end
end
