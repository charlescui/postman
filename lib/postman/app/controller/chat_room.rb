module Postman
	module App
		module Controller
			class ChatRoom < ApplicationController
				get	'/' do
					erb :index
				end

				get	'/sleep' do
					stream do |out|
						sleep 2
						out << "hello world!!!"
					end
				end
			end
		end
	end
end