# frozen_string_literal: true

require_relative '../models/patron'
require_relative '../models/package'

class SlackController
  attr_reader :patron, :params, :actions

  def initialize(params)
    # Save the params
    @params = params
    # Add the user to the database if they don't already exist
    @patron = Patron.where(user_id: params['user_id']).first_or_create!
    @patron.save
    # Actions list
    @actions = %w[feed serving full status join stats leave]
  end

  def feed
    hungry_man = @patron
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be active in the pool
    # 2) Can't be a delivery man
    # 3) Can't be waiting for a burrito
    # 4) Must wait between orders (determined by greediness)
    return 'Please join the pool.' unless hungry_man.is_active?
    return '*You* should be delivering a burrito!' if hungry_man.on_delivery?
    return 'You already have a burrito coming!' if hungry_man.waiting?
    return "Stop being so greedy! Wait #{hungry_man.time_until_hungry}s." if hungry_man.greedy?

    # Create a package for events to process
    Package.create hungry_man: hungry_man

    # Let hungry man know we've received his order
    'Our chefs are hard at work to prepare your burrito!'
  end

  def serving
    # Check if the patron is on delivery
    return "You haven't been volunteered to deliver..." unless @patron.on_delivery?
    package = @patron.active_delivery
    return "You've already acked this request..." if package.en_route
    # Ack the package
    package.en_route = true
    package.save
    'Make haste!'
  end

  def full
    # Check if patron has an in coming burrito
    msg = "You don't have any incoming burritos. Order one with: */cloudburrito feed*"
    return msg unless @patron.waiting?
    # Mark the package as received
    delivery_man = @patron.incoming_burrito.delivery_man
    @patron.incoming_burrito.delivered!
    # Notify delivery_man that he can order more burritos
    text = 'Your delivery has been acked. You can request more burritos!'
    Message.create to: delivery_man, text: text
    'Enjoy!'
  end

  def status
    return "You don't have any in coming burritos." unless @patron.waiting?
    package = @patron.incoming_burrito
    return "This burrito is on it's way!" if package.en_route
    'You burrito is still in the fridge.'
  end

  def join
    if @patron.active?
      "You are already part of the pool party!\nRequest a burrito with */cloudburrito feed*."
    else
      @patron.active!
      'Please enjoy our fine selection of burritos!'
    end
  end

  def leave
    @patron.is_active = false
    @patron.save
    'You have left the burrito pool party.'
  end

  def stats
    "Use this url to see your stats.\n#{@patron.stats_url}"
  end
end
