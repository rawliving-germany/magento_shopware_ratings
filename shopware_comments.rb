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
  json_content = JSON.parse(ARGF.read, symbolize_names: true)
  reviews = json_content.map do |review|
    ShopwareReview.new(review)
  end
else
  puts option_parser
end

reviews = reviews.delete_if do |review|
  review.sku.to_s.strip == ''
end

query = <<~SQL
  SELECT articleID, ordernumber
  FROM s_articles_details
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

sku_id_map = mysql_client.query(query, symbolize_keys: true).map do |row|
  [row[:ordernumber], row[:articleID]]
end.to_h

reviews.each do |review|
  review.articleID = sku_id_map[review.sku]
  if review.articleID.to_s.strip == ''
    error_prompt.warn("review will be skipped (SKU #{review.sku} not found)")
  end
end

insert_query = <<~SQL
  INSERT INTO s_articles_vote (articleID, name, headline, comment, points, datum, active, shop_id)
  VALUES (%{articleID}, '%{name}', '%{headline}', '%{comment}', %{points}, '%{datum}', 1, 1)
SQL

reviews.each do |review|
  puts review
  prompt.yes?('Insert this review?')
  puts insert_query % review.to_h.transform_values{|v| mysql_client.escape v}
end

exit 0
