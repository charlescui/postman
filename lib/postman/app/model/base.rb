require "virtus"

module Postman
	module App
		module Model
			class Base
				include Virtus
				attribute :id, String, :default => proc{UUID.generate.gsub("-",'')}
			end
		end
	end
end