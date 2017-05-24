# frozen_string_literal: true

# CloudBurrito
# Jackson Argo 2017

# Require models
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }

# Require controllers
Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each {|file| require file }

# Require events
Dir[File.dirname(__FILE__) + '/events/*.rb'].each {|file| require file }

require 'sinatra/base'

# CloudBurrito
# An app for downloading burritos from the cloud.
class CloudBurrito < Sinatra::Base
  Mongoid.load!('config/mongoid.yml')

  configure :production, :development do
    enable :logging
  end

  if File.exist? '.git'
    version = `git describe`
  elsif File.exist? '../../repo/HEAD'
    version = `cd ../repo && git describe`
  else
    version = Time.now
  end

  set :version, version

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == settings.slack_veri_token
  end

  ##
  ## Load secrets
  ##

  if File.exist? 'config/secrets.yml'
    secrets = YAML.load_file 'config/secrets.yml'
    secrets = secrets[settings.environment.to_s]
  end
  secrets ||= {}
  slack_veri_token = secrets['slack_veri_token']
  slack_auth_token = secrets['slack_auth_token']
  slack_veri_token ||= 'XXX_burrito_XXX'
  slack_auth_token ||= 'xoxb-???'
  set :slack_veri_token, slack_veri_token
  set :slack_auth_token, slack_auth_token

  ##
  ## Serve burritos
  ##

  puts "Version: #{settings.version}"
  puts "Environment: #{settings.environment}"
  puts "Seed: #{Random::DEFAULT.seed}"

  not_found do
    if request.path == '/slack' && request.request_method == 'POST'
      '404: Burrito Not Found!'
    elsif request.accept? 'text/html'
      @content = erb :error404
      return erb :beautify
    else
      '404: Burrito Not Found!'
    end
  end

  error 401 do
    # Return text for post in /slack
    if request.path == '/slack' && request.request_method == 'POST'
      '401: Burrito Unauthorized!'
    elsif request.accept? 'text/html'
      @content = erb :error401
      erb :beautify
    else
      '401: Burrito Unauthorized!'
    end
  end

  error 500 do
    '500: A nasty burrito was found!'
  end

  before '/slack' do
    halt 401 unless valid_token? params['token']
    halt 401 unless params['user_id']
  end

  get '/' do
    if request.accept? 'text/html'
      @content = erb :index
      erb :beautify
    else
      'Welcome to Cloud Burrito!'
    end
  end

  get '/stats' do
    @stats = {
      'patrons' => {
        'total' => Patron.count,
        'active' => Patron.where(active: true).count
      },
      'served' => {
        'burritos' => Package.where(received: true).count,
        'calories' => Package.where(received: true).count * 350
      }
    }

    if request.accept? 'text/html'
      @content = erb :stats
      erb :beautify
    elsif request.accept? 'application/json'
      return JSON.dump('ok' => true, 'stats' => @stats)
    end
  end

  get '/rules' do
    @content = erb :rules
    erb :beautify
  end

  get '/cbtp' do
    @content = erb :cbtp
    erb :beautify
  end

  get '/user' do
    id = params['id']
    # Require a user id
    halt 401 unless params['id']
    # Require that the user exists
    begin
      @patron = Patron.find(id)
    rescue
      halt 401
    end
    # Require a matching token
    halt 401 unless @patron.user_token
    halt 401 unless @patron.user_token == params['token']
    # Render the user stats
    @content = erb :user
    erb :beautify
  end

  post '/slack' do
    # Check if the user exists
    unless Patron.where(slack_user_id: params['user_id']).exists?
      logger.info "New user #{params['user_id']}"
      pool = Pool.first_or_create!(name: 'default_pool')
      Patron.create!(slack_user_id: params['user_id'], pool: pool)
      return erb :slack_new_user
    end

    # Create the controller
    controller = SlackController.new params
    # Do the needful
    cmd = params['text']
    cmd = cmd.strip unless cmd.nil?
    cmd = cmd.split(' ')[0] unless cmd.nil?
    logger.info "User #{params['user_id']} requesting #{params['text']}"
    if controller.actions.include? cmd
      controller.send(cmd)
    else
      erb :slack_help
    end
  end
end
