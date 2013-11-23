%w(
data_mapper
json
pry
sass
sinatra/base
sinatra/assetpack
).each {|d| require d}

DataMapper.setup(:default,  ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.rb")
DataMapper.finalize
DataMapper.auto_upgrade!
Dir["./helpers/*.rb"].each {|file| require file }  
Dir["./models/*.rb"].each {|file| require file }

ROOT_DIR = File.dirname(__FILE__)