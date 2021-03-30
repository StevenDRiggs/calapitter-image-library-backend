class StoredImage < ApplicationRecord
  has_and_belongs_to_many :users
  has_one_attached :image
end
