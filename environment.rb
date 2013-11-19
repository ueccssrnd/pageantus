require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default,  ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.rb")
Dir["./helpers/*.rb"].each {|file| require file }  
Dir["./models/*.rb"].each {|file| require file }  

