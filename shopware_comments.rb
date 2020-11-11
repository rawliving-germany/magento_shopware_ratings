#!/usr/bin/env ruby

require 'optparse'
require 'mysql2'
require 'tty-prompt'
require 'json'

require_relative 'lib/shopware_review'

options = {}

option_parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{$PROGRAM_NAME} [options] [input.json]"
  parser.separator "Read ratings/reviews from json file (as argument or via stdin), correlate sku and import into shopware"
  parser.on('-u', '--username DBUSERNAME', 'username for (shopware) database authentication')
  parser.on('-p', '--password DBPASSWORD', 'password for (shopware) database authentication')
  parser.on('-d', '--databasename DBNAME', 'name of (shopware) database')
  parser.on_tail("-h", "--help", "Show this message and exit") do
    puts parser
    exit
  end
end

option_parser.parse!(into: options)

if options[:databasename].to_s.strip == ''
  puts option_parser

  exit 1
end

prompt = TTY::Prompt.new
error_prompt = TTY::Prompt.new(output: STDERR)

# We want all
# "./outme | PROGRAM",
# "PROGRAM < file"
# and ""PROGRAM file" to work

if ARGF.filename != "-" or (not STDIN.tty? and not STDIN.closed?)
  json_content = JSON.parse ARGF.read
  reviews = json_content.map do |review|
    ;
  end
else
  puts option_parser
end

puts reviews

query = <<~SQL
  SELECT 
  FROM s_articles_details
  WHERE
  ;
SQL

begin
  mysql_client = Mysql2::Client.new host: 'localhost',
    username: options[:username],
    password: options[:password],
    database: options[:databasename]
rescue Mysql2::Error::ConnectionError => e
  error_prompt.error e
  puts "Maybe you want to pass mysql connection parameters:"
  puts option_parser
  exit 2
end


exit 0
