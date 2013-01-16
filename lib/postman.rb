$:.unshift File.dirname(__FILE__)

require "uuid"
require 'kramdown'
require 'ostruct'
require "sinatra/base"
require "sinatra/reloader"
require "better_errors"
require_relative "postman/configration"
require "active_support"
require 'active_support/core_ext/string/inflections'
require "active_support/core_ext/object/blank"

begin
	gem 'eventmachine'
	EM.epoll
	EM.threadpool_size = ::P::C.config[:threads] || 50
rescue Exception => e
	# do nothing
end

Dir[File.join(File.dirname(__FILE__), 'postman', 'app', 'model', '*.rb')].each{|file| require_relative file}
require_relative './postman/app/controller/application_controller'

module Postman
	def self.env
		@_env ||= ENV["ENV"] || ENV["RACK_ENV"] || "development"
	end

	module App
		module Controller
			def self.controllers_url_map
				@@_controllers_url_map ||= {'/' => ApplicationController}
			end
		end#Controller
	end#App
end#Postman

Dir[File.join(File.dirname(__FILE__), 'postman', 'app', 'controller', '*.rb')].each{|file| require_relative file}
