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

        travel_back
      end

      it 'sets the flag' do
        expect(@user.flags).to include('TEST_FLAG' => true)
      end

      it 'updates HISTORY' do
        expect(@user.flags['HISTORY'].last).to include('TEST_FLAG')

        tf = @user.flags['HISTORY'].last['TEST_FLAG']
        expect(tf[0]).to be(true)
        expect(Time.parse(tf[1])).to eq(Time.new(2021, 1, 1))
      end
    end

    context 'clear_flag' do
      before(:example) do
        @user.set_flag('TEST_FLAG', true)

        @user.clear_flag('TEST_FLAG')
      end

      it 'clears the flag' do
        expect(@user.flags).to_not include('TEST_FLAG')
      end

      it 'does not update history' do
        expect(@user.flags['HISTORY'].last).to include('TEST_FLAG')
      end
    end
  end
end
