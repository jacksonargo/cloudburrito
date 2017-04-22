# frozen_string_literal: true

require 'logger'
require 'fileutils'

# CloudBurritoLogger
# A module that add a logger method.
module CloudBurritoLogger
  def logger
    logfile = 'log/app.log'
    FileUtils.mkdir_p 'log'
    if File.writable? logfile
      @__logger ||= Logger.new('log/app.log')
    else
      @__logger ||= Logger.new(STDOUT)
    end
    @__logger
  end
end
