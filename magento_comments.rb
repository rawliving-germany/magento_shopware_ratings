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
  parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
  parser.separator "Read ratings/reviews from magento database and dumps them as json"
  parser.on('-u', '--username DBUSERNAME', 'username for (magento) database authentication')
  parser.on('-p', '--password DBPASSWORD', 'password for (magento) database authentication')
  parser.on('-d', '--databasename DBNAME', 'name of (magento) database')
  parser.on('--pretty', 'pretty print the json')
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

query = <<~SQL
  SELECT v.vote_id, v.remote_ip, rating.rating_code, v.rating_id, v.review_id, v.percent, v.value, sku, title, detail, nickname, review.created_at
  FROM rating_option_vote v
  LEFT JOIN rating_option ON v.option_id = rating_option.option_id
  LEFT JOIN rating ON rating_option.rating_id = rating.rating_id
  LEFT JOIN review_detail ON v.review_id = review_detail.review_id
  LEFT JOIN review ON v.review_id = review.review_id
  LEFT JOIN catalog_product_entity on v.entity_pk_value = catalog_product_entity.entity_id
  WHERE review.status_id = 1
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

reviews = mysql_client.query(query, symbolize_keys: true).map do |row|
  ShopwareReview.new(
    articleID: nil,
    name:     row[:nickname],
    headline: row[:title],
    comment:  row[:detail],
    points:   row[:value], # percent / 20
    datum:    row[:created_at],
    active:   1, # query should only fetch active review/ratings,
    sku:      row[:sku]
  )
end

reviews.map! do |review|
  review.to_h
end

if options[:pretty]
  puts JSON.pretty_generate reviews
else
  puts reviews.to_json
end

exit 0
