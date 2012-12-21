require_relative './base'

module Postman
	module App
		module Model
			class User < Base
				attribute :name, String
				attribute :ttl, Integer
			end
		end
	end
end