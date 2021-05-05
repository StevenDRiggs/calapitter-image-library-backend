require 'rails_helper'
require 'stored_image'


RSpec.describe StoredImage, type: :model do
  before(:context) do
    @user = User.create!(username: 'test user', email: 'test@user.com', password: 'pass')
    @si = StoredImage.create!(user: @user)
    @si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: 'test photo', content_type: 'image/jpeg')
  end

  after(:context) do
    @si.image.purge
    @si.destroy
    @user.destroy
  end

  context 'when validating url' do
    context 'with valid url' do
      context 'when url points to accepted image type' do
        let(:valid_url_with_image) {
          'https://stevendriggs.herokuapp.com/images/Steven_Riggs_photo.jpg'
        }

        it 'updates url' do
          expect(@si.update(url: valid_url_with_image)).to be_truthy
        end
      end

      context 'when url does not point to accepted image type' do
        let(:valid_url_without_image) {
          'https://www.google.com'
        }

        it 'does not update url' do
          expect(@si.update(url: valid_url_without_image)).to be(false)
        end
      end
    end

    context 'with invalid url' do
      let(:invalid_url) {
        'notaurl'
      }

      it 'does not update url' do
          expect(@si.update(url: invalid_url)).to be(false)
      end
    end

    context 'with profane url' do
      let(:profane_url) {
        'https://bitchez-guild.com/wp-content/uploads/2019/07/mockup-c7ddc589-416x416.jpg'
      }

      it 'does not update url' do
          expect(@si.update(url: profane_url)).to be(false)
      end
    end
  end
end
