require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "requires positive amount, description, date, and relationships" do
    expense = Expense.new(amount_cents: 0, description: "", spent_on: nil)
    assert_not expense.valid?
    assert_includes expense.errors[:amount_cents], "must be greater than 0"
    assert expense.errors[:description].any?
    assert expense.errors[:spent_on].any?
    assert expense.errors[:user].any?
    assert expense.errors[:category].any?
  end
end
