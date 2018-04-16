Rails.application.routes.draw do

  root 'checkouts#new'
  resources :checkouts,  only: [:new, :create, :show]

match '/client_token' => 'checkouts#client_token', via: :get
match '/checkout' => 'checkouts#checkout', via: :post
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
