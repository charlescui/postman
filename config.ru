require "pp"
require "./lib/postman"
require "ruby-debug" if Postman.env == 'development'

pp ::Postman::App::Controller.controllers_url_map

run Rack::URLMap.new(::Postman::App::Controller.controllers_url_map)