# frozen_string_literal: true

require_relative '../models/patron'
require_relative '../models/package'
require_relative '../lib/cloudburrito_logger'

class SlackController
  include CloudBurritoLogger

  attr_reader :patron, :params, :actions

  def initialize(params)
    # Save the params
    @params = params
    # Add the user to the database if they don't already exist
    @patron = Patron.where(slack_user_id: params['user_id']).first
    if @patron.nil?
      pool = Pool.first_or_create!(name: 'default_pool')
      @patron = Patron.create!(slack_user_id: params['user_id'], pool: pool)
    end
    # Actions list
    @actions = %w[feed serving full status join stats leave pool reject]
  end

  def feed
    hungry_man = @patron
    logger.info "Checking if #{hungry_man} can feed."
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be active in the pool
    # 2) Can't be a delivery man
    # 3) Can't be waiting for a burrito
    # 4) Must wait between orders (determined by greediness)
    return 'Please join the pool.' unless hungry_man.active?
    return '*You* should be delivering a burrito!' if hungry_man.on_delivery?
    return 'You already have a burrito coming!' if hungry_man.waiting?
    return "Stop being so greedy! Wait #{hungry_man.time_until_hungry}s." if hungry_man.greedy?

    # Create a package for events to process
    logger.info "Creating burrito package for #{hungry_man}."
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
    logger.info "#{@patron} has acknowledged the delivery request."
    'Make haste!'
  end

  def reject
    return "You haven't been volunteered to deliver..." unless @patron.on_delivery?
    package = @patron.active_delivery
    # Unack and mark the package as stale
    package.force_stale = true
    package.en_route = false
    package.save
    logger.info "#{@patron} has rejected the delivery request for #{@package}."
  end

  def full
    # Check if patron has an in coming burrito
    msg = "You don't have any incoming burritos. Order one with: */cloudburrito feed*"
    return msg unless @patron.waiting?
    # Mark the package as received
    delivery_man = @patron.incoming_burrito.delivery_man
    @patron.incoming_burrito.received!
    logger.info "#{@patron} has received his burrito."
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
      logger.info "#{@patron} is now active."
      'Please enjoy our fine selection of burritos!'
    end
  end

  def pool
    pool = if @params['text'].nil?
             ''
           else
             @params['text'].sub(/^\s*pool\s*/, '').strip
           end
    # Unless they give a valid pool, hit em with the list
    unless Pool.all.pluck(:name).include? pool
      msg = 'Here is a list of valid burrito pool parties:'
      Pool.each { |p| msg += "\n>*#{p.name}*" }
      return msg
    end
    # Set the pool.
    @patron.pool = Pool.find(pool)
    @patron.save
    # Tell the patron
    "Welcome to the #{pool} pool party!"
  end

  def leave
    @patron.active = false
    @patron.save
    logger.info "#{@patron} is inactive."
    'You have left the burrito pool party.'
  end

  def stats
    "Use this url to see your stats.\n#{@patron.stats_url}"
  end
end
