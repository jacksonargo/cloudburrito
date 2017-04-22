require 'logger'
require 'fileutils'
module CloudBurritoLogger
  def logger
    FileUtils.mkdir_p 'log'
    @__logger ||= Logger.new('log/app.log')
    @__logger
  end
end
