require 'rails_helper'
require 'stored_image'

RSpec.describe StoredImage, type: :model do
  before(:context) do
    @user = User.create!(username: 'test user', email: 'test@user.com', password: 'pass')
  end

  after(:context) do
    @user.destroy
  end

  context 'when creating new instance' do
    it 'creates empty instance' do
      expect {
        StoredImage.create(user: @user)
      }.to change {
        StoredImage.all.length
      }.by(1)

      si_last = StoredImage.last

      expect([si_last.url, si_last.verified, si_last.user]).to eq([nil, false, @user])
    end
  end

  context 'when adding or updating new image file'do
    let(:si) {
      StoredImage.create!(user: @user, verified: true)
    }

    before(:example) do
      si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: 'test photo', content_type: 'image/jpeg')
    end

    it 'attaches image file' do
      expect(si.image.attached?).to be(true)
    end

    it 'updates url' do
      expect(si.url).to eq(Rails.application.routes.url_helpers.rails_blob_path(si.image, only_path: true))
    end

    it 'sets verified to false' do
      expect(si.verified).to be(false)
    end
  end

  context 'when adding or updating url' do
    let(:si) {
      StoredImage.create!(user: @user)
    }

    let(:url) {
      'https://stevendriggs.herokuapp.com/images/Steven_Riggs_photo.jpg'
    }

    before(:example) do
      si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: 'test photo', content_type: 'image/jpeg')
      si.update!(verified: true)
    end

    it 'updates attached image' do
      expect {
        si.update(url: url)
      }.to change {
        si.image.filename
      }
    end

    it 'changes verified to false' do
      si.update(url: url)

      expect(si.verified).to be(false)
    end
  end
end
