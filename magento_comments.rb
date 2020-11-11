#!/usr/bin/env ruby

require 'optparse'
require 'mysql2'
require 'tty-prompt'

options = {}

option_parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
  parser.separator "Read ratings/reviews from magento database and dumps them as json"
  parser.on('-u', '--username DBUSERNAME', 'username for database authentication')
  parser.on('-p', '--password DBPASSWORD', 'password for database authentication')
  parser.on('-d', '--databasename DBNAME', 'name of database')
  parser.on('-o', '--output FILE', 'name of file to output to (json)')
  parser.on_tail("-h", "--help", "Show this message and exit") do
    puts parser
    exit
  end
end.parse!(into: options)

if options[:databasename].to_s.strip == ''
  puts option_parser
end

puts "options #{options}"

prompt = TTY::Prompt.new

ShopwareReview = Struct.new(:articleID,
                            :name,
                            :headline,
                            :comment,
                            :points,
                            :datum,
                            :active,
                            :sku,
                            keyword_init: true)

query = <<~SQL
  SELECT v.vote_id, v.remote_ip, rating.rating_code, v.rating_id, v.review_id, v.percent, v.value, sku, title, detail, nickname, review.created_at
  FROM rating_option_vote v
  LEFT JOIN rating_option ON v.option_id = rating_option.option_id
  LEFT JOIN rating ON rating_option.rating_id = rating.rating_id
  LEFT JOIN review_detail ON v.review_id = review_detail.review_id
  LEFT JOIN review ON v.review_id = review.review_id
  LEFT JOIN catalog_product_entity on v.entity_pk_value = catalog_product_entity.entity_id
  WHERE review.status_id = 1
  LIMIT 5;
SQL

mysql_client = Mysql2::Client.new host: 'localhost', username: options[:username], password: options[:password], database: options[:databasename]

reviews = mysql_client.query(query, symbolize_keys: true).map do |row|
  ShopwareReview.new(
    articleID: nil,
    headline: row[:title],
    comment:  row[:details],
    points:   row[:value], # percent / 20
    datum:    row[:created_at],
    active:   1, # query should only fetch active review/ratings,
    sku:      row[:sku]
  )
end

reviews.each do |review|
  prompt.yes?("Import #{review.inspect}")
end

exit 0
