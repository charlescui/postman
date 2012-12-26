module Postman
	module App
		module Controller
			class BlackBoard < ApplicationController
				get '/' do
				  erb :index, :layout => :layout
				end
			end
		end
	end
end
