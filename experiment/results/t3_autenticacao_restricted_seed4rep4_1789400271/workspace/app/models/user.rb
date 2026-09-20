class User < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Finds a user by email, normalizing the input the same way records are stored.
  def self.find_by_normalized_email(email)
    find_by(email: normalize_email_value(email))
  end

  def self.normalize_email_value(email)
    email.to_s.strip.downcase
  end

  private

  def normalize_email
    self.email = self.class.normalize_email_value(email)
  end
end
