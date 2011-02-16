require 'sinatra'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'digest/md5'
require 'time'
require 'json'
require 'haml'

require File.expand_path(File.join(File.dirname(__FILE__), 'muni'))
@@muni = Muni.new

get '/' do
	haml :index
end

get '/muni.json' do
	@@faves ||= YAML.load_file('settings.yml')
	arrivals = @@muni.arrivals(@@faves)
	arrivals.to_json
end

get '/browse' do
	@routes = @@muni.routes
	haml :browse_routes
end

get '/browse/:tag' do |tag|
	@route_info = @@muni.route_info(tag)
	haml :browse_route_info
end