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

options = { :mode => 'host' }

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
  options[:mode] = 'tag'
end
opts.on('-A', '--all', 'Report all hosts') do
  options[:all] = true
end
opts.on('-T', '--all-tags', 'Report all tags') do
  options[:all] = true 
  options[:mode] = 'tag'
end
opts.on('-v', '--verbose', 'Give verbose diagnostics') do
  options[:verbose] = true
end
def usage(opts)
  puts opts
  exit
end

args = opts.parse(ARGV)
usage(opts) if args.length == 0

