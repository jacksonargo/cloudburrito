# frozen_string_literal: true

require 'logger'
require 'fileutils'

# CloudBurritoLogger
# A module that add a logger method.
module CloudBurritoLogger
  def logger
    FileUtils.mkdir_p 'log'
    @__logger ||= Logger.new('log/app.log')
    @__logger
  end
end
