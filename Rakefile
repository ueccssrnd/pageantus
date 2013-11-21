task :default => [:load_db]

# add testing

task :load_db do
  require './environment'
  Dir["./models/*.rb"].each {|file| require file }
end

namespace :db do
  task :recreate => [:load_db] do
    DataMapper.auto_migrate!
    DBSeeder.seed_mmue_2013
    DataMapper.auto_upgrade!
    puts Pageant.count
    puts Round.count
    puts Candidate.count
  end
end

