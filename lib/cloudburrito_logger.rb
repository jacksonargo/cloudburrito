# frozen_string_literal: true

require 'logger'
require 'fileutils'

# CloudBurritoLogger
# A module that add a logger method.
module CloudBurritoLogger
  def logger
    @__logger ||= Logger.new(STDERR)
    @__logger
  end
end
