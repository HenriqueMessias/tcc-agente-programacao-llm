class User < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :password, presence: true, on: :create

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
