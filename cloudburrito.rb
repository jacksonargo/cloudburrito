# CloudBurrito
# Jackson Argo 2017

require_relative 'lib/patron'
require_relative 'lib/package'
require_relative 'lib/settings'
require_relative 'lib/messenger'
require_relative 'lib/controller'
require 'sinatra/base'

class CloudBurrito < Sinatra::Base

  Mongoid.load!("config/mongoid.yml")

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == Settings.verification_token
  end

  ##
  ## Serve burritos
  ##

  # Check for the necessary diddlies from slack
  before '/slack/*' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
  end

  error do
    "A nasty burrito was found!"
  end

  not_found do
    "Burrito not found!"
  end

  get '/' do
    if request.accept? "text/html"
      erb :index
    else
      "Welcome to Cloud Burrito!"
    end
  end

  post '/slack/join' do
    Controller.join params["user_id"]
  end

  post '/slack/feedme' do
    Controller.feed params["user_id"]
  end

  post '/slack/en_route' do
    Controller.en_route params["user_id"]
  end

  post '/slack/received' do
    Controller.received params["user_id"]
  end
end
