class StoredImage < ApplicationRecord
  has_one :user_image
  has_one :user, through: :user_image
  has_one_attached :image

  # instance methods
  def attach_image(img)
    self.image.attach(img)
    self.update(url: Rails.application.routes.url_helpers.rails_blob_path(self.image, only_path: true), verified: false)
  end

  def update(params)
    if params.keys.include?(:url) && params[:url] =~ /^https?:\/\//
      self.image.purge
      new_image = Down.download(params[:url], max_size: 5 * 1024 * 1024)
      self.image.attach(io: File.open(new_image), filename: new_image.original_filename, content_type: new_image.content_type)
      
      params[:verified] = false
    end
    
    super(params)
  end
end
