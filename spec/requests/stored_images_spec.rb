require 'rails_helper'
require 'stored_image'

RSpec.describe StoredImagesController, type: :request do
  describe 'GET /stored_images' do
    before(:context) do
      @admin_user = User.create!(username: 'admin username', email: 'admin@email.com', password: 'pass', is_admin: true)
      @non_admin_user = User.create!(username: 'non-admin username', email: 'non_admin@email.com', password: 'pass')

      5.times.with_index do |i|
        si = StoredImage.create!(user: @admin_user, verified: true)
        si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: "verified_image#{i}", content_type: 'image/jpeg')

        si2 = StoredImage.create!(user: @non_admin_user)
        si2.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: "unverified_image#{i}", content_type: 'image/jpeg')
      end
    end

    after(:context) do
      StoredImage.destroy_all
      @admin_user.destroy
      @non_admin_user.destroy
    end

    context 'when logged in as admin' do
      before(:example) do
        post '/login', params: {
          user: {
            usernameOrEmail: @admin_user.username,
            password: 'pass',
          },
        }

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:example) do
        remove_instance_variable(:@valid_headers)
      end

      fit 'renders json for all images' do
        get '/stored_images', headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('images')
        expect(resp_json['images']).to include('verified', 'unverified')

        vsi = resp_json['images']['verified']
        stored_vsi = StoredImage.all.where(verified: true)
        expect(vsi.length).to eq(stored_vsi.length)
        vsi.each.with_index do |vimgi, i|
          #####expect(vimg).to include(
        end
      end

      it 'renders full user information for each image' do
      end
    end

    context 'when logged in as non-admin' do
      it 'renders json for all verified images' do
      end

      it 'does not render json for unverified images 'do
      end

      it 'renders partial user info for each image' do
      end
    end

    context 'when not logged in' do
      it 'renders json for all verified images' do
      end

      it 'does not render json for unverified images 'do
      end

      it 'does not render user info for images' do
      end
    end
  end

  xdescribe 'GET /stored_images/:id' do
  end

  xdescribe 'POST /stored_images' do
  end

  xdescribe 'PATCH/PUT /stored_images/:id' do
  end

  xdescribe 'DELETE /stored_images/:id' do
  end
end
