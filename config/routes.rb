Rails.application.routes.draw do
  # get 'password_resets/new'
  # get 'password_resets/edit'
  root "static_pages#home"
  get "/help", to: "static_pages#help"
  get "/about", to: "static_pages#about"
  get "/contact", to: "static_pages#contact"
  get "/signup", to: "users#new"
  get "/login", to: "sessions#new"
  post "/login", to:"sessions#create"
  delete "/logout", to: "sessions#destroy"
  resources :users do
    #memberメソッド→ユーザーidを含むURLを扱うようになる(resourceに対してidを含むrouteを形成する)
    #collectメソッド→ユーザーに対して新しいメソッドを追加する(resourceに対して新しrouteを追加)
    member do
      get :following, :followers
    end
  end
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :relationships, only: [:create, :destroy]
  resources :microposts, only: [:create, :destroy]
end

#名前付きルーティングは_path, _urlどちらでも訪問できるが_urlは絶対パス(https://)、_pathは相対パスの形で表現される