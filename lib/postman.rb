$:.unshift File.dirname(__FILE__)

require "uuid"
require 'ostruct'
require "sinatra/base"
require_relative "postman/configration"
require "active_support"
require 'active_support/core_ext/string/inflections'
require "active_support/core_ext/object/blank"

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
				include Model

				def self.inherited(subclass)
					super
					subclass_path = subclass.to_s.gsub('Postman::App::Controller::', '').underscore
					subclass.class_eval{
						# 每个controller对应的view在BASEVIEWPATH目录下
						# 以controller为子目录名，包含了所需要的每个erb模板文件
						set :views,  "#{BASEVIEWPATH}/#{subclass_path}"
					}
					# 每个controller对应的url路径为该controller的类名（如果有模块，模块为url目录的前缀）
			    	Controller.controllers_url_map["/#{subclass_path}"] = subclass
				end

				helpers do
					def current_user
						obj = ::P::C.redis.hgetall(params[:user_credentials])
						if !obj.blank?
							User.new(obj)
						else
							# nil
							User.new(
								:id => '1234567890',
								:name => "guest",
								:ttl => 60
								)
						end						
					end

					def require_user
						unless current_user
							raise "No user found!!!"
						end
					end
				end

				dir = File.dirname(File.expand_path(__FILE__))
    			BASEVIEWPATH = "#{dir}/postman/app/view"
				
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

			    not_found do
					<<-DOC
						    _   __      __     _____                              __     ___    ____  ____
						   / | / /___  / /_   / ___/__  ______  ____  ____  _____/ /_   /   |  / __ \/  _/
						  /  |/ / __ \/ __/   \__ \/ / / / __ \/ __ \/ __ \/ ___/ __/  / /| | / /_/ // /  
						 / /|  / /_/ / /_    ___/ / /_/ / /_/ / /_/ / /_/ / /  / /_   / ___ |/ ____// /   
						/_/ |_/\____/\__/   /____/\__,_/ .___/ .___/\____/_/   \__/  /_/  |_/_/   /___/   
						                              /_/   /_/                                           
					DOC
				end

				error do
			    	<<-DOC
		    			    ______                        _          _____                          
		    			   / ____/_____________  _____   (_)___     / ___/___  ______   _____  _____
		    			  / __/ / ___/ ___/ __ \/ ___/  / / __ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
		    			 / /___/ /  / /  / /_/ / /     / / / / /   ___/ /  __/ /   | |/ /  __/ /    
		    			/_____/_/  /_/   \____/_/     /_/_/ /_/   /____/\___/_/    |___/\___/_/     
		    			                                                                            
			    	DOC
				end
			end#ApplicationController
		end#Controller
	end#App
end#Postman

Dir[File.join(File.dirname(__FILE__), 'postman', 'app', 'controller', '*.rb')].each{|file| require_relative file}
