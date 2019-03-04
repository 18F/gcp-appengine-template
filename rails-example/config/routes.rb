Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  get "/robots.txt" => "robots_txts#show"

  resources :articles
end
