task :default => [:test]

task :test do
  ruby 'models/gogo.rb'
end

task :load_db do
  require 'data_mapper'
  require './models/schema.rb'
  require './models/seeder.rb'
end

task :recreate_db => [:load_db] do
  DataMapper.auto_migrate!
  DBSeeder.seed_mmue_2013
  DataMapper.auto_upgrade!
  puts Pageant.count
end