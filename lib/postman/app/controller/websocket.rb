module Postman
	module App
		module Controller
			class Websocket < ApplicationController
				before {
					require_user
				}
				get '/' do
				  perb :index
				end
			end
		end
	end
end
