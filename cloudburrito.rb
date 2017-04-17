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

  error 500 do
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

  error 401 do
    @content = erb :error401
    erb :beautify
  end

  before '/slack' do
    halt 401 unless valid_token? params["token"]
    halt 400 unless params["user_id"]
  end

  get '/' do
    if request.accept? "text/html"
      @content = erb :index
      erb :beautify
    else
      "Welcome to Cloud Burrito!"
    end
  end

  get '/user' do
    puts "got request for /user"
    user_id = params["user_id"]
    # Require a user id
    halt 401 unless params["user_id"]
    # Require that the user exists
    "puts finding patron"
    begin
      @patron = Patron.find(user_id)
    rescue
      halt 401
    end
    # Require a matching token
    "checking of token"
    halt 401 unless @patron.user_token
    halt 401 unless @patron.user_token == params["token"]
    "patron token matches"
    # Render the user stats
    @content = erb :user
    erb :beautify
  end

  post '/slack' do
    user_id = params["user_id"]
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
    when /[Mm]y stats/
      logger.controller_action = :my_stats
      logger.response = Controller.my_stats params
    else
      logger.controller_action = :help
      logger.response = erb :slack_help
    end
    logger.save
    logger.response
  end
end
