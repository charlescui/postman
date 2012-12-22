class String
	# 如果请求是eventsource协议，则返回的内容应该为
	# data: payload\n\n
	# 格式
	def to_es
		"data: #{self}\n\n"
	end
end

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

					def exchange_name(user = nil)
						"Postman/Mc/#{user.id}/#{params[:key]}"
					end

					def is_event_source
						request.env['sinatra.accept'].include?("text/event-stream")
					end
				end

				set :connections, []

				get '/' do
					"message center."
				end

				post '/pub' do
					stream :keep_open do |out|
						user = current_user
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							exchange = channel.fanout(exchange_name(user))
							exchange.publish params[:content], :routing_key => routing_key(user), :mandatory => false do
								status 204
								out.close
							end
							out.callback{
								exchange.delete(:nowait => true, :if_unused => true)
								# channel.close
							}
						end
					end
				end#pub

				# Chunk模式
				get '/ck/sub', :provides => 'text/event-stream' do
					stream :keep_open do |out|
						# 将连接保存起来
						settings.connections << out
						# 当连接中断的时候，将该连接从池中删除
						out.callback{settings.connections.delete(out)}
						# 得到当前请求的用户
						user = current_user
						# 建立Channel
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							# 得到一个属于该用户的该Key的Exchange，并且可以将消息广播给所有绑定在这个exchange下的Queue
							exchange = channel.fanout(exchange_name(user))
							# 每个终端连接到服务器后都会得到一个queue
							# 这个queue的消息有超时时间，超过这个ttl后将会被丢弃，避免队列积累太多内容
							queue_name = uuid_queue_name(user)
							AMQP::Queue.new(channel, queue_name, :auto_delete => true, :durable => true, :arguments => { "x-message-ttl" => user.ttl }) do |queue|
								# 将队列绑定到exchange上并且设定回调
								queue.bind(exchange).subscribe do |payload|
									logger.info("Queue[#{queue.name}] receive a payload - #{payload}")
									out << (is_event_source ? payload.to_es : payload)
								end
								# 当连接中断时要删掉该queue，避免exchange继续向该queue传播消息
								out.callback{queue.delete}
							end
							# out.callback{channel.close}
						end
					end
				end#/ck/sub

				# Longpull模式
				get '/lp/sub' do
					stream :keep_open do |out|
						user = current_user
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							exchange = channel.fanout(exchange_name(user))
							queue_name = uuid_queue_name(user)
							AMQP::Queue.new(channel, queue_name, :auto_delete => true, :durable => true, :arguments => { "x-message-ttl" => user.ttl }) do |queue|
								queue.bind(exchange).subscribe do |payload|
									logger.info("Queue[#{queue.name}] receive a payload - #{payload}")
									out << (is_event_source ? payload.to_es : payload)
									out.close
								end
								out.callback{queue.delete}
							end
							# out.callback{channel.close}
						end
					end
				end#/lp/sub
			end#mc
		end#controller
	end#app
end#postman