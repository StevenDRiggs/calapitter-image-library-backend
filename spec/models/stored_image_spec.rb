require 'rails_helper'
require 'stored_image'

RSpec.describe StoredImage, type: :model do
  it 'creates a new StoredImage without url' do
    StoredImage 
  end
end
