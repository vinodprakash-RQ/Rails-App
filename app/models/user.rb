class User < ApplicationRecord
  has_secure_password
  has_many :expenses, dependent: :destroy

  EMAIL_FORMAT = /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/
  validates :email, presence: true, format: { with: EMAIL_FORMAT }, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  before_validation { self.email = email.to_s.strip.downcase }
end
