require 'json'
require 'time'
require 'sinatra/base'
require 'slack-ruby-client'

##
## Quick Goals:
##

## 1) Use mongo db as the backed
## 2) Use modpassenger or something #check
## 3) Automate builds with docker
## 4) Automate testing #check
## 5) Log every transaction

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

class Patron
  attr_reader :joined, :user_id
  attr_accessor :last_feeding, :total_feedings
  attr_accessor :last_delivery, :total_deliveries

  def initialize(args = {})
    @user_id = args["user_id"]
    @joined = args["joined"]
    @total_feedings = args["total_feedings"]
    @total_deliveries = args["total_deliveries"]
    @joined ||= Time.now
    @total_feedings ||= 0
    @total_deliveries ||= 0
  end

  def dump
    { "user_id" => @user_id, "joined" => @joined }
  end

  def to_s
    "<@#{@user_id}>"
  end
end

class Master
  attr_reader :patrons

  def initialize
    # Load the patrons
    load
    # Create a slack client
    @client = Slack::Web::Client.new
  end

  def save
    File.write "data/patrons.json", JSON::dump(@patrons.map(&:dump))
  end

  def load
    @patrons = []
    if File.exist? "data/patrons.json"
      JSON::load(File.open("data/patrons.json")).each do |patron|
        @patrons << Patron.new(patron)
      end
    end
  end

  def purge_patrons
    @patrons = []
  end

  def feed(user_id)
    # Grab the hungry patron
    hungry_man = get_patron user_id
    unless hungry_man
      return "You gotta be a patron to play."
    end
    # Grab the next delivery man
    delivery_man = @patrons.select{ |p| p.user_id != user_id }.first
    if delivery_man
      hungry_man.total_feedings += 1
      hungry_man.last_feeding = Time.now
      send_on_delivery delivery_man, hungry_man
      "<@#{delivery_man.user_id}> will deliver your burrito!"
    else
      "How about this? Get your own burrito."
    end
  end

  def join(user_id)
    unless get_patron user_id
      @patrons << Patron.new("user_id" => user_id)
      save
      "Welcome new Cloud Burrito patron!"
    else
      "You are already a patron of Cloud Burrito!"
    end
  end

  def send_on_delivery(delivery_man, hungry_man)
    msg = "Go get a burrito for <@#{hungry_man.user_id}>."
    delivery_man.total_deliveries += 1
    delivery_man.last_delivery = Time.now
    im = @client.im_open(user: delivery_man.user_id).channel.id
    @client.chat_postMessage(channel: im, text: msg)
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

  def get_patron(user_id)
    @patrons.select{ |p| p.user_id == user_id }.first
  end
end

class CloudBurrito < Sinatra::Base
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
    if headers["Accept"] = "application/json"
      return JSON.dump(burrito.patrons.map(&:dump))
    end
    burrito.patrons.join('\n')
  end

  get '/' do
    "Burritos are in the oven!"
  end
end
