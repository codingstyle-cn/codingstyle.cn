Rails.application.routes.draw do
  mount RuCaptcha::Engine => "/rucaptcha"

  get 'advertisements/show'

  use_doorkeeper do
    controllers applications: 'oauth/applications', authorized_applications: 'oauth/authorized_applications'
  end

  resources :sites
  resources :pages, path: 'wiki' do
    collection do
      get :recent
      post :preview
    end
    member do
      get :comments
    end
  end
  resources :comments
  resources :notes do
    collection do
      post :preview
    end
  end

  root to: 'home#index'

  devise_for :users, path: 'account', controllers: {
    registrations: :account,
    sessions: :sessions,
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  delete 'account/auth/:provider/unbind' => 'users#auth_unbind', as: 'unbind_account'
  post 'account/update_private_token' => 'users#update_private_token', as: 'update_private_token_account'

  resources :notifications, only: [:index, :destroy] do
    collection do
      post :clear
      get :unread
    end
  end

  resources :nodes do
    member do
      post :block
      post :unblock
    end
  end

  get 'topics/node:id' => 'topics#node', as: 'node_topics'
  get 'topics/node:id/feed' => 'topics#node_feed', as: 'feed_node_topics', defaults: { format: 'xml' }
  get 'topics/last' => 'topics#recent', as: 'recent_topics'

  resources :topics do
    member do
      post :reply
      post :favorite
      delete :unfavorite
      post :follow
      delete :unfollow
      patch :suggest
      delete :unsuggest
      post :ban
    end
    collection do
      get :no_reply
      get :popular
      get :excellent
      get :feed, defaults: { format: 'xml' }
      post :preview
    end
    resources :replies
  end

  resources :photos
  resources :likes
  resources :jobs
  resources :open_classes

  get '/search' => 'search#index', as: 'search'

  namespace :cpanel do
    root to: 'home#index'
    resources :site_configs
    resources :replies
    resources :topics do
      member do
        post :suggest
        post :unsuggest
        post :undestroy
      end
    end
    resources :nodes
    resources :sections
    resources :users
    resources :photos
    resources :pages do
      resources :versions, controller: :page_versions do
        member do
          post :revert
        end
      end
    end
    resources :comments
    resources :site_nodes
    resources :sites
    resources :locations
    resources :exception_logs do
      collection do
        post :clean
      end
    end
    resources :applications
  end

  get 'api' => 'home#api', as: 'api'
  get 'twitter' => 'home#twitter', as: 'twitter'
  get 'markdown' => 'home#markdown', as: 'markdown'

  require 'dispatch'
  mount Api::Dispatch => '/api'

  require 'sidekiq/web'
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    mount Split::Dashboard => '/split'
  end

  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  # WARRING! 请保持 User 的 routes 在所有路由的最后，以便于可以让用户名在根目录下面使用，而又不影响到其他的 routes
  # 比如 http://ruby-china.org/huacnlee
  get 'users/city/:id' => 'users#city', as: 'location_users'
  get 'users' => 'users#index', as: 'users'

  resources :users, path: '' do
    member do
      get :topics
      get :replies
      get :favorites
      get :notes
      get :blocked
      post :block
      post :unblock
      post :follow
      post :unfollow
      get :followers
      get :following
    end
  end

  match '*path', via: :all, to: 'home#error_404'
end
