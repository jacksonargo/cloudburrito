require_relative 'patron'
require_relative 'package'
require_relative 'settings'
require_relative 'messenger'
require 'sinatra/base'

##
## Quick Goals:
##

##
## Implement the following rules of play:
## * hungry_man receives the burrito
## * delivery_man delivers the burrito
## 1) You must be in the pool play - done
## 2) You can only be hungry_man once per hour - done
## 3) You can only be delivery_man once per hour - done
## 4) You must ack when your burrito is delivered
## 5) You can only have one burrito en route
##    at a time - done
## 6) You must ack when chosen as delivery_man
## 7) If you do not ack delivery_man within 5 minutes,
##    you are removed from queue
##

## Api calls needed to implement:
##
## /join - done
## /feedme
## /ack_delivery
## /ack_feedme

class CloudBurrito < Sinatra::Base

  set :environment, :development

  Mongoid.load!("config/mongoid.yml", :development)

  ##
  ## Functions
  ##

  def valid_token?(token)
    token == Settings.verification_token
  end

  def get_next_delivery_man_for(hungry_man)
    # Get all the active patrons
    candidates = Patrons.where(is_active: true)
    # Check that there are active patrons
    return nil unless candidates.exists?
    # Select delivery man based on these rules:
    # 1) Must be active
    # 2) Must no be on a delivery
    # 3) Cannot be selected more than once per sleep time
    candidates = candidates.each.select do |p|
      not (p.is_on_delivery? or p.is_sleeping? or p == hungry_man)
    end
    # Check if any patrons match the criteria
    return nil unless candidates.count > 0
    # Pick a random
    candidates.sample
  end

  def feed(hungry_man_id)
    hungry_man = Patron.where(:user_id => hungry_man_id)
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be in the pool
    # 2) Must be active
    # 3) Can't be a delivery man
    # 4) Can't be waiting for a burrito
    if not hungry_man.exists?
      return "Please join CloudBurrito!"
    end
    hungry_man = hungry_man.first
    if not hungry_man.is_active?
      return "Please join the pool!"
    elsif hungry_man.is_on_delivery?
      return "*You* should be delivering a burrito!"
    elsif hungry_man.is_already_waiting?
      return "You already have a burrito coming!"
    elsif hungry_man.is_greedy?
      return "Stop being so greedy! You need to wait #{hungry_man.time_until_hungry}s."
    end
    
    # Check if we can find delivery man
    delivery_man = get_next_delivery_man_for hungry_man
    if delivery_man
      send_on_delivery delivery_man, hungry_man
      "Burrito incoming!"
    else
      "How about this? Get your own burrito."
    end
  end

  def send_on_delivery(delivery_man, hungry_man)
    package = Package.new
    package.deliver_man = delivery_man
    package.hungry_man = hungry_man
    package.save
    msg = "Go get a burrito for <@#{hungry_man.user_id}>."
    Messenger.notify delivery_man, msg
  end

  def join(patron_id)
    patron = Patron.where(:user_id => patron_id)
    if patron.exists?
      patron = patron.first
      patron.is_active = true
      patron.save
      "Please enjoy our fine selection of burritos!"
    else
      Patron.new(:user_id => patron_id).save
      "Welcome new Cloud Burrito patron!"
    end
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
    join user_id
  end

  post '/feedme' do
    token = params["token"]
    user_id = params["user_id"]
    halt 401 unless valid_token? token
    halt 400 unless user_id
    feed user_id
  end

  get '/' do
    "Burritos are in the oven!"
  end
end
