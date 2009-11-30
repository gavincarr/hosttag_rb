#!/usr/bin/ruby
#
# Hosttag query client, redis version
#
# Usage:
#   ht <tag>
#
#   ht [-a] <tag1> <tag2>           Show hosts with tag1 AND tag2 (intersection, default)
#   ht -o <tag1> <tag2>             Show hosts with tag1 OR tags2 (union)
#
#   ht -A                           Show all hosts
#
#   ht -t <host>                    Show tags on 'host'
#   ht -t [-o] <host1> <host2>      Show tags on 'host' OR 'host2' (union, default)
#   ht -t -a <host1> <host2>        Show tags on 'host' AND 'host2' (intersection)
#
#   ht -T                           Show all tags
#

require 'rubygems'
require 'redis'
require 'optparse'

options = { :arg_type => 'tag', :all => 0, :all_key => 'all_hosts' }

opts = OptionParser.new
opts.banner = "Usage: hosttag.rb [options] <tag> [<tag2>...]"
opts.on('-?', '-h', '--help') do
  puts opts
  exit
end
opts.on('-a', '--and', 'Report hosts with ALL the given tags (AND result sets)') do
  options[:rel] = 'and'
end
opts.on('-o', '--or',  'Report hosts with ANY of the given tags (OR result sets)') do
  options[:rel] = 'or'
end
opts.on('-t', '--tag', '--tags', "Tag mode: report tags for the given hosts") do
  options[:arg_type] = 'host'
end
opts.on('-A', '--all', 'Report all hosts') do
  options[:all] += 1
end
opts.on('-T', '--all-tags', 'Report all tags') do
  options[:all] += 1
  options[:all_key] = 'all_tags'
end
opts.on('-v', '--verbose', 'Give verbose diagnostics') do
  options[:verbose] = true
end
def usage(opts)
  puts opts
  exit
end

# Parse options
begin
  args = opts.parse(ARGV) 
rescue => e
  puts "Error: " << e
  usage(opts)
end
if args.length == 0 and options[:all] == 0
  usage(opts) 
end

# Create redis object
r = Redis.new()

# Standard request
if options[:all] == 0
  # Default a rel if we have multiple args
  if args.length > 1
    options[:rel] ||= options[:arg_type] == 'tag' ? 'and' : 'or'
    puts "+ rel: #{options[:rel]}" if options[:verbose]
  end

  # Map keys to fetch
  keys = args.collect {|v| "hosttag/#{options[:arg_type]}/#{v}" }
  puts "+ keys: #{keys.join(' ')}" if options[:verbose]

  # Fetch and report
  if args.length == 1
    puts r.set_members( keys ).sort.join(' ')
  elsif options[:rel] == 'and'
    puts r.set_intersect( keys ).sort.join(' ')
  else
    puts r.set_union( keys ).sort.join(' ')
  end

# All request
else
  key = "hosttag/#{options[:all_key]}"
  key += "_noskip" if options[:all] == 1
  puts "+ key: #{key}" if options[:verbose]
  puts r.set_members(key).sort.join(' ');
end

