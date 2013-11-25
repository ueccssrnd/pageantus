task :default => [:load_db]

# add testing

task :load_db do
  require './environment'
  DataMapper.finalize
end

task :pry => [:load_db] do
  require 'pry'
  binding.pry
end

namespace :db do
  task :reseed => [:load_db] do
    DataMapper.auto_migrate!
    DBSeeder.seed_mmue_2013
    DataMapper.auto_upgrade!
    puts "Seeded! Pageant count: #{Pageant.count}"
    puts "Round count: #{Round.count}"
    puts "Category count: #{Category.count}"
    puts "Candidate count: #{Candidate.count}"
    puts "Judge count: #{Judge.count}"
  end
  
  task :clear => [:load_db] do
   DataMapper.auto_migrate!
   puts "Cleared! Pageant count: #{Pageant.count}"
  end
  
end

