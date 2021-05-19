class StoredImage < ApplicationRecord
  has_one :user_image
  has_one :user, through: :user_image
  has_one_attached :image

  validates :url, url: true, unless: -> {
    url.blank? ||
    url =~ /\/rails\/active_storage\/blobs\/redirect\/.+/
  }
  validates :url, profanity_filter: true

  # instance methods
  def attach_image(img)
    self.image.attach(img)
    self.update(url: Rails.application.routes.url_helpers.rails_blob_path(self.image, only_path: true), verified: false)
  end

  def update(params)
    if params.keys.include?(:url) && params[:url] =~ /^https?:\/\//
      new_image = Down.download(params[:url], max_size: 5 * 1024 * 1024)
      if new_image.content_type =~ /(application|image)\/(gif|jpeg|png|svg)/
        self.image.purge
        self.image.attach(io: File.open(new_image), filename: new_image.original_filename, content_type: new_image.content_type)
      else
        return false
      end
      
      params[:verified] = false
    end
    
    super(params)
  end

  def as_json(options={}, is_admin=false)
    options[:except] ||= [:id]
    
    if is_admin
      options[:include] ||= [user: {
        only: [:username, :id],
      }]
    else
      options[:include] ||= [user: {
        only: [:username],
      }]
    end

    super(options)
  end
end
