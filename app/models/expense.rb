class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :description, presence: true, length: { maximum: 500 }
  validates :spent_on, presence: true
  validates :currency, inclusion: { in: %w[USD] }

  scope :for_month, ->(date) { where(spent_on: date.beginning_of_month..date.end_of_month) }
end
