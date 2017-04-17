# CloudBurrito
# Jackson Argo 2017

require_relative 'lib/patron'
require_relative 'lib/package'
require_relative 'lib/settings'
require_relative 'lib/messenger'
require_relative 'lib/controller'
require_relative 'lib/requestlogger'
require_relative 'lib/messagelogger'
require 'sinatra/base'

class CloudBurrito < Sinatra::Base

  Mongoid.load!("config/mongoid.yml")

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == Settings.verification_token
  end

  ## Load settings
  if File.exist? "config/settings.json"
    settings = JSON.parse(File.read("config/settings.json"))
    settings = settings[Sinatra::Base.environment.to_s]
    Settings.set(settings)
  end

  ##
  ## Serve burritos
  ##

  error do
    "A nasty burrito was found!"
  end

  not_found do
    if request.accept? "text/html"
      @content = erb :error404
      return erb :beautify
    else
      "404: Burrito Not Found!"
    end
  end

  get '/' do
    if request.accept? "text/html"
      @content = erb :index
      return erb :beautify
    else
      "Welcome to Cloud Burrito!"
    end
  end

  post '/slack' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    # Add the user to the database if they don't already exist
    patron = Patron.where(user_id: params["user_id"]).first_or_create!
    logger = RequestLogger.new(uri: '/slack', method: :post, params: params)
    logger.patron = patron
    case params["text"]
    when /[Jj]oin/
      logger.controller_action = :join
      logger.response = Controller.join params
    when /[Ff]eed ?(|me)/
      logger.controller_action = :feed
      logger.response = Controller.feed params
    when /[Ee]n(\_| )route/
      logger.controller_action = :en_route
      logger.response = Controller.en_route params
    when /[Rr]eceived/
      logger.controller_action = :received
      logger.response = Controller.received params
    when /[Ss]tatus/
      logger.controller_action = :status
      logger.response = Controller.status params
    else
      logger.controller_action = :help
      logger.response = erb :slack_help
    end
    logger.save
    logger.response
  end
end
