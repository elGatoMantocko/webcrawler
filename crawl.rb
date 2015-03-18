#!/Users/elliott/.rbenv/shims/ruby

require 'open-uri'
require 'nokogiri'
require 'uri'

ARGV.each do |url|
	url = "http://" + url if not url.match(/http/)
	uri = URI(url)
	url_file = File.open(url[/\w+(?=\.com)/], "w")

	url_table = {uri.to_s => true}

	Nokogiri.HTML(open(url)).search('a').map { |a|
		link = URI.join(url, a['href']) 
		url_table[link.to_s] = false
	}

end