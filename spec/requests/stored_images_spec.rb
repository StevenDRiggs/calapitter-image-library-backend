require 'rails_helper'
require 'stored_image'

RSpec.describe StoredImagesController, type: :request do
  describe 'GET /stored_images' do
    it 'responds with json listing all stored images' do
      get stored_images_path
      expect(response.body).to eq(StoredImage.all.to_a.to_s)
    end
  end
end
