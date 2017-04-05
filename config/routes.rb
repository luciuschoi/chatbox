Rails.application.routes.draw do

  root 'welcome#index'
  resources :messages
  devise_for :users
  # get 'welcome/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount ActionCable.server, at: '/cable'

end
