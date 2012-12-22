module Postman
	module App
		module Controller
			class ChatRoom < ApplicationController
				get '/' do
				  halt erb(:login, :layout => :layout) unless params[:user]
				  erb :chat, :locals => { :user => params[:user].gsub(/\W/, '') }, :layout => :layout
				end
			end
		end
	end
end
