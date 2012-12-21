module Postman
	module App
		module Controller
			class ChatRoom < ApplicationController
				set :connections, []

				get '/' do
				  halt erb(:login, :layout => :layout) unless params[:user]
				  erb :chat, :locals => { :user => params[:user].gsub(/\W/, '') }, :layout => :layout
				end

				get '/stream', :provides => 'text/event-stream' do
				  stream :keep_open do |out|
				    settings.connections << out
				    out.callback {
				    	settings.connections.delete(out)
				    	logger.info "Connection break out!!!"
				    }
				  end
				end

				post '/' do
				  settings.connections.each { |out| out << "data: #{params[:msg]}\n\n" }
				  204 # response without entity body
				end
			end
		end
	end
end
