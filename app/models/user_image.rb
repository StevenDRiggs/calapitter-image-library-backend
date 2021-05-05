class UserImage < ApplicationRecord
  belongs_to :user
  belongs_to :stored_image
end
