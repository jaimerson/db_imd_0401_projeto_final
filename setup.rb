$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
require 'rubygems'
require 'bundler/setup'

Bundler.setup(:default)

require 'dotenv/load'
require 'sequel'
require 'pg'
require 'pry'

def database_url
  ENV.fetch('DATABASE_URL') do
    raise ArgumentError, 'Please specify database url with `export DATABASE_URL=url`'
  end
end
