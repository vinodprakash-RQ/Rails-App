class Category < ApplicationRecord
  has_many :expenses, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  before_validation { self.name = name.to_s.strip }
end
