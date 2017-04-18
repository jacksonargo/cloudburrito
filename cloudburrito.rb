# CloudBurrito
# Jackson Argo 2017

require_relative 'lib/patron'
require_relative 'lib/package'
require_relative 'lib/messenger'
require_relative 'lib/slack_controller'
require_relative 'lib/requestlogger'
require_relative 'lib/messagelogger'
require 'sinatra/base'

class CloudBurrito < Sinatra::Base

  Mongoid.load!("config/mongoid.yml")

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == settings.slack_veri_token
  end

  puts "Environment: #{settings.environment}"

  ## 
  ## Load secrets
  ##

  secrets = {}
  if File.exist? "config/secrets.yml"
    secrets = YAML.load_file "config/secrets.yml"
    secrets = secrets[settings.environment.to_s]
  end
  slack_veri_token = secrets["slack_veri_token"]
  slack_auth_token = secrets["slack_auth_token"]
  slack_veri_token ||= "XXX_burrito_XXX"
  slack_auth_token ||= "xoxb-???"
  set :slack_veri_token, slack_veri_token
  set :slack_auth_token, slack_auth_token

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
    if request.accept? "text/html"
      @content = erb :error401
      erb :beautify
    else
      "401: Burrito Unauthorized"
    end
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
    user_id = params["user_id"]
    # Require a user id
    halt 401 unless params["user_id"]
    # Require that the user exists
    begin
      @patron = Patron.find(user_id)
    rescue
      halt 401
    end
    # Require a matching token
    halt 401 unless @patron.user_token
    halt 401 unless @patron.user_token == params["token"]
    # Log this request
    RequestLogger.new(uri: '/user', method: :get, params: params, patron: @patron).save
    # Render the user stats
    @content = erb :user
    erb :beautify
  end

  post '/slack' do
    # Create the controller
    controller = SlackController.new params
    # Log this request
    logger = RequestLogger.new(
      uri: '/slack',
      method: :post,
      params: params,
      patron: controller.patron
    )
    # Do the needful
    cmd = params["text"]
    cmd = cmd.strip unless cmd.nil?
    if controller.actions.include? cmd
      logger.controller_action = cmd
      logger.response = controller.send(cmd)
    else
      logger.controller_action = :help
      logger.response = erb :slack_help
    end
    logger.save
    logger.response
  end
end
