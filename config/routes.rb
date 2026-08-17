Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "users/me", to: "users#me"
      resources :categories, only: [:index, :show]
      resources :expenses
      post "news_articles/crawl", to: "news_articles#crawl"
      resources :news_articles, only: [:index, :show]
      get "summaries/monthly", to: "summaries#monthly"
      get "summaries/categories", to: "summaries#categories"
    end
  end
end
