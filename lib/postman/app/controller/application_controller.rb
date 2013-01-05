module Postman
	module App
		module Controller
			class RequireUserException < RuntimeError; end
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
					# 用户鉴权
					# 将用户数据保存在redis的hash结构中
					# user_credentials是每个user对象的id
					def current_user
						@current_user ||= User.find_by_credentials(params[:user_credentials])
					end

					def require_user
						unless current_user
							halt "No user found!!!"
						end
					end

					def require_websocket
						halt not_found if !request.websocket?
					end

	    			# 重定义erb模板方法，默认带上全局统一的模板文件
	    			# alias :raw_erb :erb
	    			def perb(template, options={}, locals={})
	    				options = {:layout => (@@_layout ||= IO.read(settings.layout))}.merge options
	    				erb(template, options, locals)
	    			end
				end

				dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..')
				# 设置视图文件目录
    			BASEVIEWPATH = "#{dir}/postman/app/view"
    			set :views, BASEVIEWPATH
    			set :layout, File.join(BASEVIEWPATH, 'layout.erb')
				
				if respond_to? :public_folder
					set :public_folder, "#{dir}/../public"
				else
					set :public, "#{dir}/../public"
				end
				set :static, true

				configure :production, :development do
			    	enable :logging
			    end

			    configure :development do
			    	register Sinatra::Reloader
			    	also_reload __FILE__
					use BetterErrors::Middleware
					BetterErrors.application_root = File.expand_path("..", __FILE__)
			    end

			    not_found do
					perb :"404", :views => BASEVIEWPATH
				end

				error do
			    	perb :"500", :views => BASEVIEWPATH
				end
			end#ApplicationController
		end
	end
end
