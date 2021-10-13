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

      it 'renders user information for each image' do
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

      it 'renders json for all verified images' do
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
        end
      end

      it 'does not render json for unverified images 'do
        get '/stored_images', headers: @valid_headers

        expect(JSON.parse(response.body)['images']).to_not include('unverified')
      end
    end

    context 'when not logged in' do
      it 'renders json for all verified images' do
        get '/stored_images'

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
        end
      end

      it 'does not render json for unverified images 'do
        get '/stored_images'

        expect(JSON.parse(response.body)['images']).to_not include('unverified')
      end
    end
  end

  describe 'GET /stored_images/:id' do
    before(:context) do
      travel_to(Time.new(2021, 1, 1))
      @admin_user = User.create!(username: 'admin username', email: 'admin@email.com', password: 'pass', is_admin: true)
      @non_admin_user = User.create!(username: 'non-admin username', email: 'nonadmin@email.com', password: 'pass')

      @verified_si = StoredImage.create!(user: @admin_user)
      @verified_si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: 'verified_image', content_type: 'image/jpeg')
      @verified_si.update!(verified: true)

      @unverified_si = StoredImage.create!(user: @non_admin_user)
      @unverified_si.attach_image(io: File.open(Rails.root.join('spec', 'models', 'Steven_Riggs_Photo.jpg')), filename: 'unverified_image', content_type: 'image/jpeg')
      travel_back
    end

    after(:context) do
      @verified_si.destroy
      @unverified_si.destroy
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

      it 'renders json for image' do
        get "/stored_images/#{@verified_si.id}", headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('image')
        expect(resp_json['image']).to include('url' => @verified_si.url, 'user' => {
          'username' => @verified_si.user.username,
          'id' => @verified_si.user.id,
        })
        expect(resp_json['image']).to include('created_at', 'updated_at')
        expect([Time.parse(resp_json['image']['created_at']), Time.parse(resp_json['image']['updated_at'])]).to eq([@verified_si.created_at, @verified_si.updated_at])

        get "/stored_images/#{@unverified_si.id}", headers: @valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('image')
        expect(resp_json['image']).to include('url' => @unverified_si.url, 'user' => {
          'username' => @unverified_si.user.username,
          'id' => @unverified_si.user.id,
        })
        expect(resp_json['image']).to include('created_at', 'updated_at')
        expect([Time.parse(resp_json['image']['created_at']), Time.parse(resp_json['image']['updated_at'])]).to eq([@unverified_si.created_at, @unverified_si.updated_at])
      end

      it 'does not render errors' do
        get "/stored_images/#{@verified_si.id}", headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')

        get "/stored_images/#{@unverified_si.id}", headers: @valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'when logged in as non-admin' do
      before(:context) do
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

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when viewing own image' do
        it 'renders limited json for image' do
          get "/stored_images/#{@unverified_si.id}", headers: @valid_headers

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('image')
          expect(resp_json['image']).to include('url' => @unverified_si.url, 'user' => {
            'username' => @unverified_si.user.username,
          })
          expect(resp_json['image']).to include('created_at', 'updated_at')
          expect([Time.parse(resp_json['image']['created_at']), Time.parse(resp_json['image']['updated_at'])]).to eq([@unverified_si.created_at, @unverified_si.updated_at])
        end

        it 'does not render errors' do
          get "/stored_images/#{@unverified_si.id}", headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end

      context "when viewing other's image" do
        context 'when viewing verified image' do
          it 'renders limited json for image' do
            get "/stored_images/#{@verified_si.id}", headers: @valid_headers

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('image')
            expect(resp_json['image']).to include('url' => @verified_si.url, 'user' => {
              'username' => @verified_si.user.username,
            })
            expect(resp_json['image']).to include('created_at', 'updated_at')
            expect([Time.parse(resp_json['image']['created_at']), Time.parse(resp_json['image']['updated_at'])]).to eq([@verified_si.created_at, @verified_si.updated_at])
          end

          it 'does not render errors' do
            get "/stored_images/#{@unverified_si.id}", headers: @valid_headers

            expect(JSON.parse(response.body)).to_not include('errors')
          end
        end

        context 'when viewing unverified image' do
          let(:other_unverified_si) {
            StoredImage.create!(user: @admin_user)
          }

          it 'does not render image' do
            get "/stored_images/#{other_unverified_si.id}", headers: @valid_headers

            expect(JSON.parse(response.body)).to_not include('image')
          end

          it 'renders errors' do
            get "/stored_images/#{other_unverified_si.id}", headers: @valid_headers

            resp_json = JSON.parse(response.body)
            expect(resp_json).to include('errors')
            expect(resp_json['errors']).to include('May only view own unverified image')
          end
        end
      end
    end

    context 'when not logged in' do
      it 'does not render image' do
        get "/stored_images/#{@verified_si.id}"

        expect(JSON.parse(response.body)).to_not include('image')

        get "/stored_images/#{@unverified_si.id}"

        expect(JSON.parse(response.body)).to_not include('image')
      end

      it 'renders errors' do
        get "/stored_images/#{@verified_si.id}"

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Must be logged in')

        get "/stored_images/#{@unverified_si.id}"

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Must be logged in')
      end
    end
  end

  describe 'POST /stored_images' do
    context 'when logged in' do
      let(:admin_user) {
        User.create!(username: 'admin username', email: 'admin@email.com', password: 'pass', is_admin: true)
      }

      let(:non_admin_user) {
        User.create!(username: 'non-admin username', email: 'nonadmin@email.com', password: 'pass')
      }

      it 'creates new stored image for logged in user' do
        post '/login', params: {
          user: {
            usernameOrEmail: admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        expect {
          post '/stored_images', params: {
            stored_image: {
              userId: admin_user.id,
            },
          }, headers: valid_headers
        }.to change {
          StoredImage.all.length
        }.by(1)
        expect(StoredImage.last.user).to eq(admin_user)

        post '/login', params: {
          user: {
            usernameOrEmail: non_admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        expect {
          post '/stored_images', params: {
            stored_image: {
              userId: non_admin_user.id,
            },
          }, headers: valid_headers
        }.to change {
          StoredImage.all.length
        }.by(1)
        expect(StoredImage.last.user).to eq(non_admin_user)
      end

      it 'renders json for new stored image' do
        post '/login', params: {
          user: {
            usernameOrEmail: admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        post '/stored_images', params: {
          stored_image: {
            userId: admin_user.id,
          },
        }, headers: valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('url' => StoredImage.last.url, 'user' => {
          'username' => admin_user.username,
          'id' => admin_user.id,
        }, 'verified' => false)

        post '/login', params: {
          user: {
            usernameOrEmail: non_admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        post '/stored_images', params: {
          stored_image: {
            userId: non_admin_user.id,
          },
        }, headers: valid_headers

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('url' => StoredImage.last.url, 'user' => {
          'username' => non_admin_user.username,
        }, 'verified' => false)
      end

      it 'does not render errors' do
        post '/login', params: {
          user: {
            usernameOrEmail: admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        post '/stored_images', params: {
          stored_image: {
            userId: admin_user.id,
          },
        }, headers: valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')

        post '/login', params: {
          user: {
            usernameOrEmail: non_admin_user.username,
            password: 'pass',
          },
        }

        valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }

        post '/stored_images', params: {
          stored_image: {
            userId: non_admin_user.id,
          },
        }, headers: valid_headers

        expect(JSON.parse(response.body)).to_not include('errors')
      end
    end

    context 'when not logged in' do
      let(:user) {
        User.create!(username: 'user', email: 'user@email.com', password: 'pass')
      }

      it 'does not create new stored image' do
        expect {
          post '/stored_images', params: {
            stored_image: {
              userId: user.id
            },
          }
        }.to_not change {
          StoredImage.all.length
        }
      end

      it 'renders errors' do
        post '/stored_images', params: {
          stored_image: {
            userId: user.id
          },
        }

        resp_json = JSON.parse(response.body)
        expect(resp_json).to include('errors')
        expect(resp_json['errors']).to include('Must be logged in')
      end
    end
  end

  describe 'PATCH/PUT /stored_images/:id' do
    before(:context) do
      travel_to(Time.new(2021, 1, 1))
      @admin_user = User.create!(username: 'admin username', email: 'admin@email.com', password: 'pass', is_admin: true)
      @non_admin_user = User.create!(username: 'non-admin username', email: 'nonadmin@email.com', password: 'pass')

      @admin_si = StoredImage.create!(user: @admin_user)
      @non_admin_si = StoredImage.create!(user: @non_admin_user)
      travel_back
    end

    after(:context) do
      @admin_user.destroy
      @non_admin_user.destroy
      @admin_si.destroy
      @non_admin_si.destroy
    end

    after(:example) do
      @admin_si.reload
      @non_admin_si.reload
    end

    context 'when logged in as admin' do
      before(:context) do
        post '/login', params: {
          user: {
            userenameOrEmail: @admin_user.username,
            password: 'pass',
          },
        }

        @valid_headers = {
          'Authorization' => "Bearer #{JSON.parse(response.body)['token']}",
        }
      end

      after(:context) do
        remove_instance_variable(:@valid_headers)
      end

      context 'when updating own stored image' do
        let(:valid_params) {
          {
            stored_image: {
              url: 'https://unsplash.com/photos/1XnXnRdzGbk/',
              verified: true,
            },
          }
        }

        it 'updates stored image' do
          expect {
            patch "/stored_images/#{@admin_si.id}", params: valid_params, headers: @valid_headers

            @admin_si.reload
          }.to change {
            [@admin_si.url, @admin_si.verified]
          }
        end

        it 'renders json for updated stored image' do
          travel_to(Time.new(2021, 2, 2))
          patch "/stored_images/#{@admin_si.id}", params: valid_params, headers: @valid_headers

          @admin_si.reload
          travel_back

          resp_json = JSON.parse(response.body)
          expect(resp_json).to include('stored_image')
          expect(resp_json['stored_image']).to include('url' => @admin_si.url, 'verified' => @admin_si.verified)
          expect(resp_json['stored_image']).to include('created_at', 'updated_at')
          expect([Time.parse(resp_json['stored_image']['created_at']), Time.parse(resp_json['stored_image']['updated_at'])]).to eq([@admin_si.created_at, @admin_si.updated_at])
        end

        it 'does not render errors' do
          patch "/stored_images/#{@admin_si.id}", params: valid_params, headers: @valid_headers

          expect(JSON.parse(response.body)).to_not include('errors')
        end
      end

      context "when updating other's stored image" do
        before(:context) do
          @update_params = {
            stored_image: {
              url: 'https://unsplash.com/photos/1XnXnRdzGbk/',
              verified: true,
            },
          }
        end

        after(:context) do
          remove_instance_variable(:@update_params)
        end

        context 'when updating url' do
          it 'does not update store image' do
          end

          it 'returns json for non-updated stored image' do
          end

          it 'renders errors' do
          end
        end

        context 'when updating verified' do
          it 'updates stored image' do
          end

          it 'renders json for updated stored image' do
          end

          it 'does not render errors' do
          end
        end
      end
    end

    context 'when logged in as non-admin' do
      context 'when updating own stored image' do
        it 'updates stored image' do
        end

        it 'renders json for updated stored image' do
        end

        it 'does not render errors' do
        end
      end

      context "when updating other's stored image" do
        it 'does not update stored image' do
        end

        it 'renders json for non-updated stored image' do
        end

        it 'renders errors' do
        end
      end
    end

    context 'when not logged in' do
      it 'does not update stored image' do
      end

      it 'does not render json for stored image' do
      end

      it 'renders errors' do
      end
    end
  end

  xdescribe 'DELETE /stored_images/:id' do
  end
end
