require 'rails_helper'
require 'stored_image'


include ActiveSupport::Testing::TimeHelpers


RSpec.describe StoredImagesController, type: :request do
  describe 'GET /stored_images' do
    before(:context) do
      @admin_user = User.create!(username: 'admin username', email: 'admin@email.com', password: 'pass', is_admin: true)
      @non_admin_user = User.create!(username: 'non-admin username', email: 'non_admin@email.com', password: 'pass')

      travel_to(Time.new(2021, 1, 1))
      5.times.with_index do |i|
        si = StoredImage.create!(user: @admin_user)
        si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: "verified_image#{i}", content_type: 'image/jpeg')
        si.update!(verified: true)

        si2 = StoredImage.create!(user: @non_admin_user)
        si2.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: "unverified_image#{i}", content_type: 'image/jpeg')
      end
      travel_back
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

      it 'renders json for all images' do
        get '/stored_images', headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('images')
        expect(resp_json['images']).to include('verified', 'unverified')

        vsi = resp_json['images']['verified']
        stored_vsi = StoredImage.all.where(verified: true)
        expect(vsi.length).to eq(stored_vsi.length)
        vsi.each.with_index do |vimg, i|
          expect(vimg).to include('url' => stored_vsi[i].url, 'verified' => stored_vsi[i].verified)
          expect(vimg).to include('created_at', 'updated_at')
          expect([Time.parse(vimg['created_at']), Time.parse(vimg['updated_at'])]).to eq([stored_vsi[i].created_at, stored_vsi[i].updated_at])
        end

        usi = resp_json['images']['unverified']
        stored_usi = StoredImage.all.where(verified: false)
        expect(usi.length).to eq(stored_usi.length)
        usi.each.with_index do |uimg, i|
          expect(uimg).to include('url' => stored_usi[i].url, 'verified' => stored_usi[i].verified)
          expect(uimg).to include('created_at', 'updated_at')
          expect([Time.parse(uimg['created_at']), Time.parse(uimg['updated_at'])]).to eq([stored_usi[i].created_at, stored_usi[i].updated_at])
        end
      end

      it 'renders full user information for each image' do
        get '/stored_images', headers: @valid_headers

        vsi = JSON.parse(response.body)['images']['verified']
        stored_vsi = StoredImage.all.where(verified: true)
        vsi.each.with_index do |vimg, i|
          expect(vimg).to include('user' => {
            'username' => @admin_user.username,
            'id' => @admin_user.id,
          })
        end
      end
    end

    context 'when logged in as non-admin' do
      before(:example) do
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

      after(:example) do
        remove_instance_variable(:@valid_headers)
      end

      fit 'renders json for all verified images' do
        get '/stored_images', headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('images')
        expect(resp_json['images']).to include('verified')

        vsi = resp_json['images']['verified']
        stored_vsi = StoredImage.all.where(verified: true)
        expect(vsi.length).to eq(stored_vsi.length)
        vsi.each.with_index do |vimg, i|
          expect(vimg).to include('url' => stored_vsi[i].url, 'user' => {
            'username' => @admin_user.username,
          })
          expect(vimg['user']).to_not include('id')
        end
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
