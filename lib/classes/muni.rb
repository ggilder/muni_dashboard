class Muni
	BASE_URL = 'http://webservices.nextbus.com/service/publicXMLFeed?'
	PREDICTIONS_URL = BASE_URL + 'command=predictions&a=sf-muni'
	ROUTES_URL = BASE_URL + 'command=routeList&a=sf-muni'
	ROUTE_INFO_URL = BASE_URL + 'command=routeConfig&a=sf-muni&r='
	PREDICTIONS_LIMIT = 3
	
	def routes
		doc = api_data(ROUTES_URL)
		routes = doc.search('route').map do |route|
			{:tag => route['tag'], :title => route['title']}
		end
	end
	
	def route_info(tag)
		url = ROUTE_INFO_URL + tag
		doc = api_data(url)
		stop_info = {}
		routeInfo = {}
		doc.search('route').each do |route|
			routeInfo[:tag] = route['tag']
			routeInfo[:title] = route['title']
			# collect stop info
			route.xpath('./stop').each do |stop|
				stop_info[stop['tag']] = {
					:title => stop['title'],
					:stop_id => stop['stopId']
				}
			end
			# collect directions
			routeInfo[:directions] = []
			route.xpath('./direction').each do |direction|
				directionInfo = {:title => direction['title'], :stops => []}
				direction.xpath('./stop').each do |stop|
					directionInfo[:stops] << {
						:tag => stop['tag'], 
						:title => stop_info[stop[:tag]][:title], 
						:stop_id => stop_info[stop[:tag]][:stop_id]
					}
				end
				routeInfo[:directions] << directionInfo
			end
		end
		routeInfo
	end
	
	def arrivals(faves)
		arrivals = []
		faves.each do |fave|
			arrivals << stop_arrivals(fave['route'], fave['stop'])
		end
		
		# return hash with data and last updated info
		{ :data => arrivals, :as_of => Time.now.to_i }
	end
	
	def stop_arrivals(route, stop)
		url = PREDICTIONS_URL + "&r=#{route}&stopId=#{stop}"
		doc = api_data(url)
		parse_arrivals(doc)
	end
	
	def api_data(url)
		doc = Nokogiri::XML(open(url))
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
				predictions = predictions.uniq.sort_by {|x| x.to_i}.slice(0, PREDICTIONS_LIMIT).map {|x| (x == '0') ? 'now' : x}.join(', ')
				(predictions == 'now') ? predictions : predictions + ' min'
			else
				"No current predictions"
			end
		end
		results
	end
end