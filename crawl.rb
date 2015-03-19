#!/Users/elliott/.rbenv/shims/ruby

require 'mongo'
require 'open-uri'
require 'nokogiri'

webcrawler_db = Mongo::Connection.new.db('webcrawler')
webcrawler_db.collection_names.each { |name| puts name }

ARGV.each do |root|
  # check that open-uri will be able to open the url
	root = "http://" + root if not root.match(/http/)
	uri = URI(root)
	#url_file = File.open(root[/\w+(?=\.com)/], "w")
	url_coll = webcrawler_db[root[/\w+(?=\.com)/]]

  # initialize the url table
	index = { :url => uri.to_s, :visited => true}
  url_coll.insert(index) if not url_coll.find_one(url: uri.to_s)

  # populate the table from the root url
  # find each url in the HTML doc
  puts "crawling: #{uri.to_s}"
	Nokogiri.HTML(open(root)).search('a').map { |a|
		link = URI.join(uri.to_s, a['href']) 
    entry = { :url => link.to_s, :visited => false }
    
    #DEBUG
    #puts "#{entry[:url]}\na href=#{link.host}, root=#{uri.host} equal?=#{link.host == uri.host}\n#{url_coll.find_one(url: link.to_s)}\n\n"
		#puts entry if link.host == uri.host and not url_coll.find_one(url: link.to_s)
    
    # populate the mongodb collection with the url content
    url_coll.insert(entry) if link.host == uri.host and not url_coll.find_one(url: link.to_s) and not link.to_s['#']
	}

  url_coll.find(:visited => false).each do |doc|
    puts "crawling: #{doc["url"]}"

    begin
	    Nokogiri.HTML(open(doc["url"])).search('a').map { |a|
		    link = URI.join(uri.to_s, a['href']) 
        entry = { :url => link.to_s, :visited => false }
      
        #DEBUG
        #puts "#{entry[:url]}\na href=#{link.host}, parent=#{doc.url.host} equal?=#{link.host == uri.host}\n#{url_coll.find_one(url: link.to_s)}\n\n"
		    #puts entry if link.host == uri.host and not url_coll.find_one(url: link.to_s) and not link.to_s[/.pdf/]
        
        # populate the mongodb collection with the url content
        url_coll.insert(entry) if link.host == uri.host and not url_coll.find_one(url: link.to_s) and not link.to_s[/.pdf|.mp3/] and not link.to_s['#']
	    }
    rescue ArgumentError => error
      puts error
    rescue URI::InvalidURIError => error
      puts error
    end
    
    # update the mongo doc that the url is visited
    url_coll.update({"_id" => doc["_id"]}, {"$set" => {"visited" => true}})
  end

  """
  # visit unvisited nodes in the url table and populate the table 
  # with nodes that are not currently in the table
  url_table.each do |node|
    fixed_url = URI(node[:url])
    next if node[:visited]
    begin
	    Nokogiri.HTML(open(fixed_url.to_s)).search('a').map { |a|
		    link = URI.join(uri.to_s, a['href']) 
        entry = { :url => link.to_s, :visited => false }
		    puts entry if link.host == uri.host and not url_table.any? { |thing| thing[:url] == entry[:url] }
		    url_table.push(entry) if link.host == uri.host and not url_table.any? { |thing| thing[:url] == entry[:url] }
      }
      node[:visited] = true
    rescue OpenURI::HTTPError => error
      puts error.io
    end
  end

  # print the url table to the file
  url_table.each do |node|
    url_file.puts node[:url]
  end

  # close the file
  url_file.close
  """
end

