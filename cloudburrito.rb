require 'json'
require 'time'
require 'sinatra/base'
require 'slack-ruby-client'
require 'mongoid'

##
## Quick Goals:
##

## 1) Use mongo db as the backed
## 2) Use modpassenger or something #check
## 3) Automate builds with docker #check
## 4) Automate testing #check
## 5) Log every transaction #semi implemented

##
## Implement the following rules of play:
## * hungry_man receives the burrito
## * delivery_man delivers the burrito
## 1) You must be in the pool play
## 2) You can only be hungry_man once per hour
## 3) You can only be delivery_man once per hour
## 4) You must ack when your burrito is delivered
## 5) You can only have one burrito en route
##    at a time
## 6) You must ack when chosen as delivery_man
## 7) If you do not ack delivery_man within 5 minutes,
##    you are removed from queue
##

## Api calls needed to implement:
##
## /join
## /feedme
## /ack_delivery
## /ack_feedme

# Class to access settings
class Settings
  data = JSON::parse File.read('config/settings.json')
  @@verification_token = data["verification_token"]
  @@auth_token = data["auth_token"]

  def self.verification_token
    @@verification_token
  end
  def self.auth_token
    @@auth_token
  end
  def self.save_patrons
    "data/patrons.json"
  end
end

# Class to store data for the participants
class Patron
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :is_active, type: Boolean, default: true
  field :is_on_delivery, type: Boolean, default: false
  field :is_hungry, type: Boolean, default: false
  field :last_feeding, type: Time, default: Time.now
  field :last_delivery, type: Time, default: Time.now
  field :total_feedings, type: Integer, default: 0
  field :total_deliveries, type: Integer, default: 0
  field :_id, type: String, default: ->{ user_id }

  def to_s
    "<@#{user_id}>"
  end
end

class Master
  attr_reader :patrons

  def initialize
    # Create a slack client
    @client = Slack::Web::Client.new
  end

  def feed(user_id)
    # Grab the hungry patron
    hungry_man = Patron.find(user_id)
    unless hungry_man
      return "You gotta be a patron to play."
    end
    hungry_man.is_hungry = true
    hungry_man.save
    # Grab the next delivery man
    delivery_man = Patron.where(is_hungry: false).first
    if delivery_man
      send_on_delivery delivery_man, hungry_man
      "<@#{delivery_man.user_id}> will deliver your burrito!"
    else
      "How about this? Get your own burrito."
    end
  end

  def join(user_id)
    # Check if the user already exists
    patron = Patron.where(:user_id => user_id)
    if patron.exists?
      patron = patron.first
      patron.is_active = true
      patron.save
      "Please enjoy our fine selection of burritos!"
    else
      Patron.new(:user_id => user_id).save
      "Welcome new Cloud Burrito patron!"
    end
  end

  def send_on_delivery(delivery_man, hungry_man)
    hungry_man.total_feedings += 1
    hungry_man.last_feeding = Time.now
    hungry_man.save
    delivery_man.total_deliveries += 1
    delivery_man.last_delivery = Time.now
    msg = "Go get a burrito for <@#{hungry_man.user_id}>."
    notify delivery_man, msg
  end

  def notify(patron, msg)
    if false
      im = @client.im_open(user: patron.user_id).channel.id
      @client.chat_postMessage(channel: im, text: msg)
    end
  end

  def leave(user_id)
    if get_patron user_id
      @patrons.delete_if{ |p| p.user_id == user_id }
      "You are no longer a Cloud Burrito patron. \
So who's gonna get your burritos now?"
    else
      "You never were a Cloud Burrito patron. Have you considered joining?"
    end
  end
end

class CloudBurrito < Sinatra::Base

  set :environment, :development

  Mongoid.load!("config/mongoid.yml", :development)

  def valid_token?(token)
    token == Settings.verification_token
  end

  # Configure slack
  Slack.configure do |config|
    config.token = Settings.auth_token
  end

  # Create our Dungeon Master
  burrito = Master.new

  # Serve burritos

  error do
    "A nasty burrito was found!"
  end

  not_found do
    "Burrito not found!"
  end

  post '/join' do
    halt 401 unless valid_token? params["token"]
    halt 400 unless params["user_id"]
    burrito.join params["user_id"]
  end

  post '/leave' do
    halt 401 unless valid_token? params["token"]
    halt 400 unless params["user_id"]
    burrito.leave params["user_id"]
  end

  post '/feedme' do
    halt 401 unless valid_token? params["token"]
    halt 400 unless params["user_id"]
    burrito.feed params["user_id"]
  end

  get '/list_patrons' do
    halt 401 unless valid_token? params["token"]
    if headers["Accept"] == "application/json"
      return JSON.dump(Patron.each.map(&:attributes))
    end
    Patron.each.map(&:to_s).join("\n")
  end

  get '/' do
    "Burritos are in the oven!"
  end
end
