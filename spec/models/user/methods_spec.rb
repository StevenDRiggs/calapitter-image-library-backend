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

      it 'updates HISTORY' do
        expect(@user.flags['HISTORY'].last).to eq('TEST_FLAG' => [true, Time.now])
      end
    end
  end
end
