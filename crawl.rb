#!/Users/elliott/.rbenv/shims/ruby

require 'open-uri'
require 'nokogiri'
require 'uri'

ARGV.each do |root|
  # check that open-uri will be able to open the url
	root = "http://" + root if not root.match(/http/)
	uri = URI(root)
	url_file = File.open(root[/\w+(?=\.com)/], "w")

  # initialize the url table
	url_table = {uri.to_s => true}

  # populate the table from the root url
	Nokogiri.HTML(open(root)).search('a').map { |a|
		link = URI.join(uri.to_s, a['href']) 
		url_table[link.to_s] = false
	}

  # print the url table to the file
  url_table.each do |key, value|
    url_file.puts "#{key} : #{value}"
  end

  # close the file
  url_file.close
end

