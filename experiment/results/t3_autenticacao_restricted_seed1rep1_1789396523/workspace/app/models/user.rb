class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, presence: true, length: { minimum: 6 }, on: :create
end
