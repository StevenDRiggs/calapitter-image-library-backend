class User < ApplicationRecord
  has_secure_password
  has_many :user_images
  has_many :stored_images, through: :user_images
  has_one_attached :avatar
  has_many_attached :images

  validates :username, :email, presence: true
  validates :username, :email, uniqueness: true, profanity_filter: true
  validates :username, length: {minimum: 2}
  validates :email, email: true
  validates :password, length: {minimum: 3}, presence: true, on: :create
  validates :password, length: {minimum: 3}, presence: true, on: :update, unless: ->(record) {record.password.blank?}


  # class methods

  def self.find_by_username_or_email(username_or_email)

    user = self.find_by(username: username_or_email)
    unless user
      user = self.find_by(email: username_or_email)
    end

    return user
  end


  # instance methods

  def as_json(options={})
    options[:except] ||= [:id, :created_at, :updated_at, :password_digest]
    super(options)
  end

  def set_flag(flag, value)
    self.flags[flag] = value
    self.flags['HISTORY'] << [flag, value, Time.now]

    self.save
  end

  def clear_flag(flag)
    self.flags = self.flags.except(flag)

    self.save(validate: false)
  end

  def usernameOrEmail=(username_or_email)
    # method defined only for parameter acceptance; should always be empty string
  end
end
