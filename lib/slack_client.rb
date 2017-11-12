# frozen_string_literal: true

# SlackClient
# A module to create the slack client

require 'slack-ruby-client'
require 'yaml'

module SlackClient
  def slack_client
    environment = ENV['RACK_ENV']

    # Nothing do do if we've already created it
    unless @__slack_client

      # We can load the token from a file
      if File.exist? 'config/secrets.yml'
        secrets = YAML.load_file 'config/secrets.yml'
        secrets = secrets[environment]
        slack_auth_token = secrets['slack_auth_token'] unless secrets.nil?
      end

      # Environmnet variables take precedent
      unless ENV['SLACK_AUTH_TOKEN'].nil?
        slack_auth_token = ENV['SLACK_AUTH_TOKEN']
      end

      # Set the default
      slack_auth_token ||= 'xoxb-???'

      Slack.configure do |config|
        config.token = slack_auth_token
      end
      @__slack_client = Slack::Web::Client.new
    end

    # Return the client
    @__slack_client
  end
end
