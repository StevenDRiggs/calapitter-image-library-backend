require 'rails_helper'


RSpec.describe 'routing', type: :routing do
  context 'non-RESTful routing' do
    it 'routes post /signup to users#create' do
      expect(post('/signup')).to route_to('users#create')
    end

    it 'routes post /login to users#login' do
      expect(post('/login')).to route_to('users#login')
    end
  end

  context 'RESTful routing' do
    context 'routes stored_images properly' do
      it 'routes get /stored_images to stored_images#index' do
        expect(get('/stored_images')).to route_to('stored_images#index')
      end

      it 'routes post /stored_images to stored_images#create' do
        expect(post('/stored_images')).to route_to('stored_images#create')
      end

      it 'routes get /stored_images/:id to stored_images#show' do
        expect(get('/stored_images/1')).to route_to('stored_images#show', id: '1')
      end

      it 'routes patch/put /stored_images/:id to stored_images#update' do
        expect(patch('/stored_images/1')).to route_to('stored_images#update', id: '1')
        expect(put('/stored_images/1')).to route_to('stored_images#update', id: '1')
      end

      it 'routes delete /stored_images/:id to stored_images#destroy' do
        expect(delete('/stored_images/1')).to route_to('stored_images#destroy', id: '1')
      end
    end

    context 'routes users properly' do
      it 'routes get /users to users#index' do
        expect(get('/users')).to route_to('users#index')
      end

      it 'routes post /users to users#create' do
        expect(post('/users')).to route_to('users#create')
      end

      it 'routes get /users/:id to users#show' do
        expect(get('/users/1')).to route_to('users#show', id: '1')
      end

      it 'routes patch/put /users/:id to users#update' do
        expect(patch('/users/1')).to route_to('users#update', id: '1')
        expect(put('/users/1')).to route_to('users#update', id: '1')
      end

      it 'routes delete /users/:id to users#destroy' do
        expect(delete('/users/1')).to route_to('users#destroy', id: '1')
      end
    end

    context 'routes users/stored_images properly' do
      it 'routes get /users/:user_id/stored_images to stored_images#index' do
        expect(get('/users/1/stored_images')).to route_to('stored_images#index', user_id: '1')
      end

      it 'routes post /users/:user_id/stored_images to stored_images#create' do
        expect(post('/users/1/stored_images')).to route_to('stored_images#create', user_id: '1')
      end

      it 'routes get /users/:user_id/stored_images/:id to stored_images#show' do
        expect(get('/users/1/stored_images/1')).to route_to('stored_images#show', user_id: '1', id: '1')
      end

      it 'routes patch/put /users/:user_id/stored_images/:id to stored_images#update' do
        expect(patch('/users/1/stored_images/1')).to route_to('stored_images#update', user_id: '1', id: '1')
        expect(put('/users/1/stored_images/1')).to route_to('stored_images#update', user_id: '1', id: '1')
      end

      it 'routes delete /users/:user_id/stored_images/:id to stored_images#show' do
        expect(delete('/users/1/stored_images/1')).to route_to('stored_images#destroy', user_id: '1', id: '1')
      end
    end
  end
end
