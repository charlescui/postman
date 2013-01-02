module Postman
	module App
		module Controller
			class Websocket < ApplicationController
				get '/' do
				  perb :index
				end
			end
		end
	end
end
