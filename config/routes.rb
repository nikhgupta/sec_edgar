require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  mount Sidekiq::Web => "/monitor", as: :monitor

  get '/monitor/status'  => "monitor#status"
  get '/monitor/dropbox' => "monitor#dropbox"
end
