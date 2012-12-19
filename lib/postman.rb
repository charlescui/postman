$:.unshift File.dirname(__FILE__)

require "amqp"
require "sinatra/base"
require "better_errors"
require_relative "postman/configration"
require "active_support"
require 'active_support/core_ext/string/inflections'

Dir[File.join(File.dirname(__FILE__), 'postman', 'app', 'model', '*.rb')].each{|file| require_relative file}

module Postman
	def self.env
		@_env ||= ENV["ENV"] || ENV["RACK_ENV"] || "development"
	end

	module App
		module Controller
			def self.controllers_url_map
				@@_controllers_url_map ||= {'/' => ApplicationController}
			end

			class ApplicationController < Sinatra::Base
				def self.inherited(subclass)
					super
			    	Controller.controllers_url_map['/'+subclass.to_s.gsub('Postman::App::Controller::', '').underscore] = subclass
				end

				dir = File.dirname(File.expand_path(__FILE__))
    
				set :views,  "#{dir}/postman/app/view"
				if respond_to? :public_folder
					set :public_folder, "../#{dir}/public"
				else
					set :public, "../#{dir}/public"
				end
				set :static, true

				configure :production, :development do
			    	enable :logging
			    end

			    configure :development do
					use BetterErrors::Middleware
					BetterErrors.application_root = File.expand_path("..", __FILE__)
			    end
			end#ApplicationController
		end#Controller
	end#App
end#Postman

Dir[File.join(File.dirname(__FILE__), 'postman', 'app', 'controller', '*.rb')].each{|file| require_relative file}
