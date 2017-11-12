# frozen_string_literal: true

require 'typhoeus'

endpoint = '127.0.0.1:3000/slack'
token = 'XXX_burrito_dev_XXX'
cmds = %w[feed serving full status join stats leave]
usrs = (1..25).map(&:to_s)

# Generate the possible params

params_choices = []
cmds.each do |cmd|
  usrs.each do |usr|
    params_choices << { token: token, text: cmd, user_id: usr }
  end
end

# Create the requests

hydra = Typhoeus::Hydra.new max_concurrency: 80
100_000.times do
  params = params_choices.sample
  req = Typhoeus::Request.new(endpoint, method: :post, params: params)
  hydra.queue req
end

# Run it

hydra.run
