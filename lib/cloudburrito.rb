# CloudBurrito
# Jackson Argo 2017

require_relative 'patron'
require_relative 'package'
require_relative 'settings'
require_relative 'messenger'
require_relative 'controller'
require 'sinatra/base'

class CloudBurrito < Sinatra::Base

  set :environment, :development

  Mongoid.load!("config/mongoid.yml", :development)

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == Settings.verification_token
  end

  ##
  ## Serve burritos
  ##

  error do
    "A nasty burrito was found!"
  end

  not_found do
    "Burrito not found!"
  end

  post '/join' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    Controller.join user_id
  end

  post '/feedme' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    Controller.feed user_id
  end

  post '/en_route' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    Controller.en_route user_id
  end

  post '/received' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    Controller.received user_id
  end

  get '/' do
    "Burritos are in the oven!"
  end
end
