require_relative './base'

module Postman
	module App
		module Model
			class User < Base
				attribute :name, String
				# 允许该用户保存消息的时间
				attribute :ttl, Integer
				# 消息中心发给每个机构的唯一身份识别
				attribute :private_key, String
				# 用户身份认证的token
				attribute :credentials, String

				# 访问token
				def user_credentials
					self.credentials || self.generate_credentials
				end

				# 生成并保存credentials
				def generate_credentials
					self.credentials = UUID.generate.gsub('-','')
					::P::C.redis.multi do
						::P::C.redis.hset("Login::Credentials", credentials, self.id)
						self.save
					end
					self.credentials
				end

				# 重置这个token
				def reset_crendentials
					::P::C.redis.multi do
						::P::C.redis.hdel("Login::Credentials", credentials)
						self.del_attr
						self.save
					end
				end

				# 通过credentials找到某个用户
				def self.find_by_credentials(credentials)
					uid = ::P::C.redis.hget("Login::Credentials", credentials)
					uid && self.find(uid)
				end
			end
		end
	end
end