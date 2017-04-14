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
    case params["text"]
    when /[Jj]oin/
      return Controller.join params
    when /[Ff]eed ?(|me)/
      return Controller.feed params
    when /[Ee]n(\_| )route/
      return Controller.en_route params
    when /[Rr]eceived/
      return Controller.received params
    when /[Ss]tatus/
      return Controller.status params
    else
      erb :slack_help
    end
  end
end
