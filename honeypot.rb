#!/usr/bin/env ruby
#
# Honey Pot v 1.0
#
# This is a simple command-line application
# that creates a very simple honeypot.
#
# Author::    Kent 'picat' Gruber
# Copyright:: Copyright (c) 2016 Kent Gruber
# License::   MIT

# Required Gems
require 'colorize'
require 'trollop'
require 'socket'
require 'logger'

# Gimme some dat logging.
module Logging
  def logger
    Logging.logger
  end

  def self.logger
    @logger ||= Logger.new "#{Time.new.to_s.split(" ")[1]}_honeypot.log"
  end
end

# Main +Application+ class that does the majority
# of the logic for this application. Relies on celluloid
# to provide concurrency, and Logging as a mixin to provide
# logging for this class.
class Application
  include Logging

  def initialize(options)
    @options = options
    setup
  end

  def setup
    @port = @options[:port] || @port = 8080
    @banner = @options[:banner] || @banner = 'MS-IIS WEB SERVER 5.0'
    @options[:Logging] ? @log = true : @log = false
  end

  def start
    logger.info("STARTING honeypot on PORT: #{@port} with BANNER: #{@banner}") if @log
    server = TCPServer.new(@port)
    server.listen(1)
    puts "Starting Honey Pot v 1.0".blue.bold
    puts "Listening on port:".bold + " #{@port}"
    puts "Fake Banner:".bold + " #{@banner}"
    puts
    loop do
      begin
        Thread.fork(server.accept) do |client| 
          r_port, r_ip = Socket.unpack_sockaddr_in(client.getpeername)
          puts "[+]".red.bold + " Caught on #{@port} -- #{r_ip}:#{r_port}"
          logger.warn("CAUGHT on PORT: #{@port} -- #{r_ip}:#{r_port}") if @log
          client.puts @banner
          client.close
        end
      rescue => e
        logger.error("#{e}") if @log
        puts "[error] ".red + e
      end
    end
  end

end

# CTRL+C Interupt 
trap("SIGINT") { puts "\n[info] ".green + "Honey Pot Shutting Down"; exit; }

# Default option to help menu if nothing is set.
foo = ARGV[0] || ARGV[0] = '-h'

# Available options.
opts = Trollop::options do
  banner "Honey".yellow.bold + "Pot".white.bold
  version "Honey Pot v 1.0"
  opt :start, "Start the application"
  opt :banner, "Provide a fake banner",:type => :string 
  opt :port, "Listen on a specific port", :type => :int
  opt :lol, "Rainbow support, because we need it"
  opt :Logging, "Log all connections."
end

require 'lolize/auto' if opts[:lol]

app = Application.new(opts)

app.start if opts[:start]
