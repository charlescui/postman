# -*- coding: utf-8 -*-

require "json"
require 'sinatra-websocket'

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
						"#{(user || current_user).private_key}.#{params[:key]}"
					end

					def bind_routing_key(user = nil)
						"#{routing_key(user)}.#"
					end

					def direct_routing_key(user = nil)
						"#{(user || current_user).private_key}.#{(user || current_user).id}"
					end

					def uuid_queue_name(user = nil)
						"#{routing_key(user)}.#{UUID.generate.to_s.gsub('-','')}"
					end

					def exchange_name(user = nil)
						"Postman/Mc/#{user.id}/#{params[:key]}"
					end

					def is_event_source
						request.env['sinatra.accept'] && request.env['sinatra.accept'].include?("text/event-stream")
					end
				end

				set :connections, []

				get '/' do
					"message center."
				end

				get '/pub' do
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
				# 如果约束是event-source协议，
				# 则需要在路由后面加上约束条件 :provides => 'text/event-stream'

				# 当API访问这个订阅接口时，
				# 可以使用支持chunk方式的http client库
				# 比如em-http-request
				# 下面这个例子是客户端维持一个chunk的长连接
				# 支持断线重连

				# require 'em-http-request'

				# def request_persistent(&blk)
				# 	http = EventMachine::HttpRequest.new('http://localhost:9999/mc/ck/sub?key=abc', :connect_timeout => 0, :inactivity_timeout => 0).get
				# 	http.stream { |chunk| p chunk }
				# 	back = proc{
				# 		request_persistent(&blk)
				# 	}
				# 	http.callback &back
				# 	http.errback &back
				# end

				# def receive_with_chunk
				# 	EventMachine.run do
				# 		request_persistent{
				# 			puts "Loop again"
				# 		}
				# 	end
				# end
				get '/ck/sub' do
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

				# WebScoket模式
				get '/websocket' do
					require_user
					require_websocket
					request.websocket do |ws|
						ws.onopen do
							AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
								@exchange = channel.direct("websocket::exchange")
								@queue_name = uuid_queue_name(current_user)
								AMQP::Queue.new(channel, @queue_name, :auto_delete => true, :durable => true, :arguments => { "x-message-ttl" => current_user.ttl }) do |queue|
									@queue = queue
									@queue.bind(@exchange, :routing_key => direct_routing_key(current_user)).subscribe do |payload|
										# em-webcosket要求数据必须负责utf-8编码
										# 否则服务主动抛错
										payload.force_encoding("UTF-8") if payload.respond_to?(:force_encoding)
										ws.send(payload)
									end
								end
							end
						end
						ws.onmessage do |msg|
							if @exchange
								begin
									data = JSON.parse(msg)
									if data.is_a?(Hash) and data["to"]
										send_data_pack = {
											:from => current_user.id, 
											:content => data["content"]
										}.to_json
										# 多个接收人的情况
										data["to"].split(',').each do |uid|
											EM.next_tick do
												user = User.find(uid)
												@exchange.publish send_data_pack, :routing_key => direct_routing_key(user), :mandatory => false if user
											end
										end
									end
								rescue Exception => e
									raise e
								end
							end
						end
						ws.onclose do
							@queue.delete if @queue
						end
					end
				end#websocket
			end#mc
		end#controller
	end#app
end#postman