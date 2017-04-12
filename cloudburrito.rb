#!/usr/bin/ruby -w

require 'json'
require 'time'
require 'sinatra'
require 'slack-ruby-client'

class Settings
  attr_reader :verification_token, :auth_token

  def initialize
    data = JSON::parse File.read('settings.json')
    @verification_token = data["verification_token"]
    @auth_token = data["auth_token"]
  end
end

class CloudBurrito
  attr_accessor :data

  def initialize
    # Load the patrons
    @patrons = []
    if File.exist? "patrons.json"
      JSON::load(File.open("patrons.json")).each do |patron|
        @patrons << Patron.new(patron)
      end
    end
    # Create a slack client
    @client = Slack::Web::Client.new
  end

  def save
    File.write "patrons.json", JSON::dump(@patrons.map(&:dump))
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
    { user_id: @user_id, joined: @joined }
  end
end

# Load settings
settings = Settings.new

# Configure slack
Slack.configure do |config|
  config.token = settings.auth_token
end

# Create our cloud burrito
burrito = CloudBurrito.new

# Serve our burrito
error do
  "A nasty error occured!"
end

not_found do
  "This page does not exist."
end

post '/join' do
  if params["token"] == settings.verification_token
    burrito.join params["user_id"]
  else
    403
  end
end

post '/leave' do
  if params["token"] == settings.verification_token
    burrito.leave params["user_id"]
  else
    403
  end
end

post '/feedme' do
  if params["token"] == settings.verification_token
    burrito.feed params["user_id"]
  else
    403
  end
end
