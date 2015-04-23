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
require 'diaspora-api'
require 'optparse'
require 'ostruct'

def get_name(id)
	if id > 0
		user = @vk.users.get(user_ids: id, fields: "screen_name")
		if user[0]
			return user[0].first_name + " " + user[0].last_name, user[0].screen_name
		else
			return nil
		end
	elsif id < 0
		g = @vk.groups.getById(group_id: -id)
		if g[0]
			return g[0].name, g[0].screen_name
		else
			return nil
		end
	end
	return nil
end

def format_post(vk_post, tags)
	post = vk_post.text
	if vk_post.attachments != nil
		vk_post.attachments.each {|a|
			if a.type == "photo"
				if a.photo.photo_1280!=nil
					post += "\n![image](" + a.photo.photo_1280 + ")"
				elsif a.photo.photo_604!=nil
					post += "\n![image](" + a.photo.photo_604 + ")"
				elsif a.photo.photo_807!=nil
					post += "\n![image](" + a.photo.photo_807 + ")"
				end
			end
		}
	end
	if vk_post.copy_history
		name, screen_name = get_name(vk_post.copy_history[0].owner_id)
		post += "\nReposted from ["+name+"](https://vk.com/"+screen_name+"):\n"
		post += format_post(vk_post.copy_history[0], "")
	end
	if vk_post.signer_id
		author_name, screen_name = get_name(vk_post.signer_id)
		if !author_name
			author_name = "Author"
		end
		if !screen_name
			screen_name = "id" + vk_post.signer_id.to_s
		end
		post += "\n["+author_name+"](https://vk.com/" + screen_name + ")"
	end
	post = post.gsub("http://vk.com", "https://vk.com")
	post += "\n";
	if tags != nil
		post+=tags+"\n"
	end
	return post
end

cliaspora_path="cliaspora"
timestamps_dir=File.join(Dir.home, "vk2diaspora.timestamps")

options = OpenStruct.new
opts = OptionParser.new do |opts|
	opts.banner = "Usage: vk2diaspora.rb -v <pagename> -d <name@pod.host> -a <aspectname> -p <password> [options]"

	opts.on("-v", "--vk-page PAGE", "vk page short address") do |v|
		options.page_domain = v
	end
	opts.on("-d", "--diaspora-account ACCOUNT", "D* account") do |v|
		options.account = v
	end
	opts.on("-a", "--aspect ASPECT", "aspect name (use name \"public\" for public posts)") do |v|
		options.aspect = v
	end
	opts.on("-p", "--password PASSWORD", "password for D* account") do |v|
		options.password = v
	end
	opts.on("-t", "--tags TAGS", "additional tags (optional)") do |v|
		options.tags = v
	end
end
opts.parse!


if options.page_domain == nil or options.account == nil or options.aspect == nil or options.password == nil
	puts opts
	exit
end

if not options.account.include? "@"
	puts "Wrong account name supplied: " + options.account
	exit
end

username = options.account.gsub(/(.+)@(.+)/, '\1')
podhost = options.account.gsub(/(.+)@(.+)/, '\2')

begin
	Dir.mkdir(timestamps_dir, 0700)
rescue Errno::EEXIST
end

timestamp_file = File.join(timestamps_dir, options.account)

diaspora_c = DiasporaApi::Client.new
if not diaspora_c.login("https://" + podhost, username, options.password)
	puts "Failed to log in to D*"
	exit
end


VkontakteApi.configure do |config|
	config.api_version = '5.21'
end
@vk = VkontakteApi::Client.new

entries = @vk.wall.get(domain: options.page_domain).items.reverse

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
	if i == entries.count
		puts "No new entries"
		exit
	end
end

last_posted_nr = i

for i in last_posted_nr...entries.count do

	timestamp = entries[i].date
	if timestamp_saved > timestamp
		next
	end

	post = format_post(entries[i], options.tags)
	post = post.gsub("\n", "  \n")
	puts post
	resp = diaspora_c.post(post, options.aspect)

	status = resp.code.to_i
	puts "Status: "
	puts status

	if status == 200 or status == 302
		File.open(timestamp_file, "w") { |file|
			file.puts timestamp
		}
		timestamp_saved = timestamp
	else
		puts "Something went wrong. Exiting."
		exit
	end

end

