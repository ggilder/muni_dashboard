require 'sinatra'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'digest/md5'
require 'time'
require 'json'
require 'haml'

get '/' do
	haml :index
end

get '/muni.json' do
	@@faves ||= YAML.load_file('settings.yml')
	m = Muni.new
	arrivals = m.arrivals(@@faves)
	arrivals.to_json
end

class Muni
	PREDICTIONS_URL = 'http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=sf-muni'
	CACHE_EXPIRY = 60
	@@cache = {}
	
	def arrivals(faves)
		faves_key = Digest::MD5.hexdigest(faves.inspect)
		
		if (cache_fresh?(faves_key))
			arrivals = cache_data(faves_key)
		else
			arrivals = []
			faves.each do |fave|
				arrivals << stop_arrivals(fave['route'], fave['stop'])
			end
			cache_update(faves_key, arrivals)
		end
		
		# really, the data passed back should include info on when it was last updated.
		# perhaps we need a more structured json object with status, valid_as_of, etc
		arrivals
	end
	
	def cache_fresh?(key)
		return false if @@cache[key].nil? || @@cache[key][:data].nil? || @@cache[key][:updated].nil?
		return true if (Time.now.to_i - @@cache[key][:updated]) <= CACHE_EXPIRY
		return false
	end
	
	def cache_data(key)
		(@@cache[key]) ? @@cache[key][:data] : nil
	end
	
	def cache_update(key, data)
		@@cache[key] = {}
		@@cache[key][:data] = data
		@@cache[key][:updated] = Time.now.to_i
	end
	
	def stop_arrivals(route, stop)
		url = PREDICTIONS_URL + "&r=#{route}&stopId=#{stop}"
		doc = Nokogiri::XML(open(url))
		parse_arrivals(doc)
	end
	
	def parse_arrivals(doc)
		results = {}
		doc.search('predictions').each do |prediction|
			results[:route] = prediction['routeTag']
			results[:stop] = prediction['stopTitle']
			predictions = []
			prediction.xpath('./direction').each do |direction|
				results[:direction] = direction['title'] unless results[:direction]
				arrivals = direction.xpath('./prediction')
				if (arrivals.length > 0)
					 predictions = predictions + arrivals.map {|item| item['minutes']}
				end
			end
			
			results[:predictions] = if (predictions.length > 0)
				predictions.uniq.sort_by {|x| x.to_i}.slice(0, 5).map {|x| (x == 0) ? 'now' : x}.join(', ') + ' min'
			else
				"No current predictions"
			end
		end
		results
	end
end