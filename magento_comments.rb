#!/usr/bin/env ruby

require 'optparse'

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

exit 0
