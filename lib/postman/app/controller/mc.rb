module Postman
	module App
		module Controller
			class Mc < ApplicationController
				get '/' do
					"message center."
				end

				get '/pub' do
					stream do |out|
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							exchange = channel.default_exchange
							AMQP::Queue.new(channel, params[:key], :auto_delete => true, :durable => true) do |queue|
								exchange.publish params[:content], :routing_key => queue.name do
									out << "hihihi"
									channel.close do |close_ok|
										out << {:status => 0, :msg => 'ok'}.to_json
									end
								end
							end
						end
					end
				end#pub

				get '/sub' do
					stream :keep_open do |out|
						AMQP::Channel.new(::P::C.amqp) do |channel, open_ok|
							AMQP::Queue.new(channel, params[:key], :auto_delete => true, :durable => true) do |queue|
								queue.subscribe do |payload|
									out << payload
								end
							end
						end
					end
				end#sub
			end
		end
	end
end