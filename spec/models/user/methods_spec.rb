require 'rails_helper'
require 'user'


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
end
