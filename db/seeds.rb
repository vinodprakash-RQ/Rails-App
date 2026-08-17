%w[Food Travel Shopping Bills Entertainment].each { |name| Category.find_or_create_by!(name: name) }

if Rails.env.development?
  demo = User.find_or_create_by!(email: "demo@example.com") { |u| u.password = "password123"; u.password_confirmation = "password123" }
  food = Category.find_by!(name: "Food")
  demo.expenses.find_or_create_by!(description: "Sample lunch", spent_on: Date.current) { |e| e.amount_cents = 1250; e.category = food }
end
