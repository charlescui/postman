require "redis"
require "amqp"

module Postman
	module Configration
		class << self
			def config!
				YAML.load(File.open File.join(File.dirname(__FILE__), "..", "..", "config","server.yml"))
			end
			
			def config
				@config ||= self.config!
			end
			
			def redis
				@redis ||= Redis.connect(:url => config[:redis])
			end

			def amqp
				@amqp ||= AMQP.connect(:host => config[:amqp])
			end
		end
	end
end

P = Postman
P::C = Postman::Configration