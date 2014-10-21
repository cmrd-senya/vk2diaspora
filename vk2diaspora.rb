#!/usr/bin/ruby
# encoding: utf-8

#
#    Copyright 2014 A. Varnin
#    
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'vkontakte_api'
require 'open3'

cliaspora_path="cliaspora"
timestamps_dir=File.join(Dir.home, "vk2diaspora.timestamps")

page_domain=ARGV[0]
account=ARGV[1]
aspect=ARGV[2]
tags=ARGV[3]

if page_domain == nil or account == nil or aspect == nil
	puts "Usage vk2diaspora <vk page short address> <diaspora account> <diaspora aspect> [additional tags]"
	exit
end

begin
	Dir.mkdir(timestamps_dir, 0700)
rescue Errno::EEXIST
end

timestamp_file = File.join(timestamps_dir, account)

@vk = VkontakteApi::Client.new


entries = @vk.wall.get(domain: page_domain).reverse

timestamp_saved = 0

if File.exists?(timestamp_file)
	File.open(timestamp_file) { |file|
		s = file.gets
	 	timestamp_saved = s.to_i
	}
end


i=0

while timestamp_saved >= entries[i].date
	i += 1
	if i == entries.length - 1
		puts "No new entries"
		exit
	end
end

last_posted_nr = i

for i in last_posted_nr...(entries.length - 1) do

	timestamp = entries[i].date
	if timestamp_saved > timestamp
		next
	end
	url = ""
	post = entries[i].text
	entries[i].attachments.each {|a| 
		if a.type == "photo"
			url = a.photo.src_xbig
		end
	}
	if url.length > 0
		post += "\n![image](" + url + ")"
	end
	post = post.gsub("http://vk.com", "https://vk.com")
	post = post.gsub("<br>", "\n")
	post+="\n";
	if tags != nil
		post+=tags+"\n"
	end

	puts post
	w, wt = Open3.pipeline_w (cliaspora_path + " -a " + account + " post " + aspect) 
	w.puts post
	w.close

	status = wt[0].value.to_i
	puts "Status: "
	puts status

	if status == 0
		File.open(timestamp_file, "w") { |file|
			file.puts timestamp
		}
		timestamp_saved = timestamp
	else
		puts "Something went wrong. Exiting."
		exit
	end

end

