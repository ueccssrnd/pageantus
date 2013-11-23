task :default => [:load_db]

# add testing

task :load_db do
  require './environment'
end

namespace :db do
  task :reseed => [:load_db] do
    DataMapper.auto_migrate!
    DBSeeder.seed_mmue_2013
    DataMapper.auto_upgrade!
    puts Pageant.count
    puts Round.count
    puts Candidate.count
  end
  
  task :clear => [:load_db] do
   DataMapper.auto_migrate!
   puts Pageant.count
    
  
  end
  
end

