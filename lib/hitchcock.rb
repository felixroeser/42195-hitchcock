__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

require 'bundler'
Bundler.setup

require 'marathon'
require 'zk'
require 'erb'
require 'logging'

require "hitchcock/version"
require "hitchcock/hacky"

module Hitchcock

  def self.logging
    return @logger unless @logger.nil?

    @logger = Logging.logger(STDOUT)
    @logger.level = :debug
    @logger
  end

end
