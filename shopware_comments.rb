#!/usr/bin/env ruby

# SPDX-FileCopyrightText: 2020 Felix Wolfsteller
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
  error_prompt.error "input missing (file argument, or pipe data via stdin)"
  puts option_parser

  exit 1
end

reviews = reviews.delete_if do |review|
  review.sku.to_s.strip == ''
end

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

query = <<~SQL
  SELECT articleID, ordernumber
  FROM s_articles_details
  ;
SQL

sku_id_map = mysql_client.query(query, symbolize_keys: true).map do |row|
  [row[:ordernumber], row[:articleID]]
end.to_h

reviews.each do |review|
  review.articleID = sku_id_map[review.sku]
  if review.articleID.to_s.strip == ''
    error_prompt.warn("review will be skipped (SKU #{review.sku} not found)")
  end
end

reviews.delete_if do |review|
  review.articleID.to_s.strip == ''
end

# STR_TO_DATE hack removes the timezone info (like '+01:00') but parses it as
# seconds in order to work in strict mode (which only accepts perfect matches)
insert_query = <<~SQL
  INSERT INTO s_articles_vote (articleID, name, headline, comment, points, datum, active, shop_id, answer, email)
  VALUES (%{articleID}, '%{name}', '%{headline}', '%{comment}', %{points}, STR_TO_DATE('%{datum}', '%%Y-%%m-%%d %%T +%%s%%S'), 1, 1, '', '')
SQL

reviews.each do |review|
  query = insert_query % review.to_h.transform_values{|v| (v.is_a? Numeric) ? v : mysql_client.escape(v.to_s)}
  puts query
  mysql_client.query query
end

exit 0
