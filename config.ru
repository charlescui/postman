require "pp"
require "better_errors"
require "./lib/postman"
if Postman.env == 'development'
	require "ruby-debug"
end

pp ::Postman::App::Controller.controllers_url_map

run Rack::URLMap.new(::Postman::App::Controller.controllers_url_map)