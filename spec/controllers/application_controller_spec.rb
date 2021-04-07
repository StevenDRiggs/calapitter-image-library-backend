require 'rails_helper'
require 'application_controller'


RSpec.describe ApplicationController do
  before(:all) do
    @payload = {payload: 'payload'}
    ac = ApplicationController.new
    ENV['SECRET_KEY_BASE'] = 'secret'
    @encoded = ac.encode_token(@payload)
  end

  context 'JWT' do
    describe '#encode_token' do
      it 'encodes a payload' do
        expect(@encoded).to eq('eyJhbGciOiJIUzI1NiJ9.eyJwYXlsb2FkIjoicGF5bG9hZCJ9.vowVLx0snUbiLv7ajozX30sXlDmRcpqPqCJ94tU0KjU')
      end
    end

    describe '#auth_header', type: :request do
      it 'returns the value at the "Authorization" header' do
        headers = {'Authorization' => "Bearer #{@encoded}"}

        post('/test_auth_header', headers: headers)

        expect(response.body).to eq("Bearer #{@encoded}")
      end
    end

    describe '#decoded_token', type: request do
      it 'returns nil if auth_header fails' do
        post('test_decoded_token')

        expect(response.body).to be(nil)
      end
    end
  end
end
