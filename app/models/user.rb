class User < ApplicationRecord
  has_secure_password
  has_and_belongs_to_many :stored_images
  has_one_attached :avatar
  has_many_attached :images
end
