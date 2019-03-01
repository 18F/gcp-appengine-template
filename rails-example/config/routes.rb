Rails.application.routes.draw do
  get 'welcome/index'
  get "/robots.txt" => "robots_txts#show"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :articles

  root 'welcome#index'
end
