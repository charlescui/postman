module Postman
	module App
		module Controller
			class Mc < ApplicationController
				helpers do
					def routing_key(user = nil)
						"#{(user || current_user).name}.#{params[:key]}"
					end

					def bind_routing_key(user = nil)
						"#{routing_key(user)}.#"
					end

					def uuid_queue_name(user = nil)
						"#{routing_key(user)}.#{UUID.generate.to_s.gsub('-','')}"
					end
				end

				get '/' do
					"message center."
				end

				get '/pub' do
					stream do |out|
						user = current_user
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							exchange = channel.fanout("Postman/Mc/#{user.id}")
							exchange.publish params[:content], :routing_key => routing_key(user), :mandatory => false do
								out << {:status => 0, :msg => 'ok'}.to_json
							end
							out.callback{
								exchange.delete(:nowait => true, :if_unused => true)
								# channel.close
							}
						end
					end
				end#pub

				# Chunk模式
				get '/ck/sub' do
					stream :keep_open do |out|
						out << "Hello #{Time.now}        "
						# # 得到当前请求的用户
						# user = current_user
						# # 建立Channel
						# AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
						# 	# 得到一个属于该用户的Exchange，并且可以将消息广播给所有
						# 	exchange = channel.fanout("Postman/Mc/#{user.id}")
						# 	# 每个终端连接到服务器后都会得到一个queue
						# 	# 这个queue的消息有超时时间，超过这个ttl后将会被丢弃，避免队列积累太多内容
						# 	queue_name = uuid_queue_name(user)
						# 	AMQP::Queue.new(channel, queue_name, :auto_delete => true, :durable => true, :arguments => { "x-message-ttl" => user.ttl }) do |queue|
						# 		logger.info(queue_name)
						# 		# 将队列绑定到exchange上并且设定回调
						# 		queue.bind(exchange).subscribe do |payload|
						# 			logger.info("Queue[#{queue.name}] receive a payload - #{payload}")
						# 			out << payload
						# 		end
						# 		# 当连接中断时要删掉该queue，避免exchange继续向该queue传播消息
						# 		out.callback{queue.delete}
						# 	end
						# 	# out.callback{channel.close}
						# end
					end
				end#/ck/sub

				# Longpull模式
				get '/lp/sub' do
					stream :keep_open do |out|
						user = current_user
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							exchange = channel.fanout("Postman/Mc/#{require_user}")
							AMQP::Queue.new(channel, uuid_queue_name(user), :auto_delete => true, :durable => true, :arguments => { "x-message-ttl" => user.ttl }) do |queue|
								queue.bind(exchange).subscribe do |payload|
									logger.info("Queue receive a payload - #{payload}")
									out << payload
									out.close
								end
								out.callback{queue.delete}
							end
							# out.callback{channel.close}
						end
					end
				end#/lp/sub
			end
		end
	end
end