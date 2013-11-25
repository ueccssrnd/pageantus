require 'yaml'

#Used to get data from the text files in the data directory
class DBSeeder
  @@data_directory = 'data/'

  def self.seed_mmue_2013
    self.seed_pageant
    self.seed_rounds
    self.seed_categories
    self.seed_candidates
    self.seed_judges
    
    Pageant.activate(Pageant.first.id)
    Round.activate(Round.first.id)
    Category.activate(Category.first.id)
    
  end

  def self.seed_scores(pageant_id = 1)
    
    Category.all(pageant_id: pageant_id).each do |category|
      Judge.all(pageant_id: pageant_id).each do |judge|
        Candidate.all(pageant_id: 1).each do |candidate|
          Score.new({
              pageant_id:  pageant_id,
              judge_id: judge.id,
              category_id: category.id, 
              candidate_id: candidate.id,
              score: rand(75..100)
            }).save
        end
      end
    end
  end
  
  def self.seed_candidates
    seed_model "candidate"
  end
  
  def self.seed_categories
    seed_model "category"
  end
  
  def self.seed_rounds
    seed_model "round"
  end
  
  def self.seed_judges
    seed_model "judge"
  end
  
  def self.seed_pageant
    Pageant.create (get_yaml "mmue2013")
  end
  
# Must have singular model_name both in the file name and in the file itself.
  def self.seed_model (model_name)
    model = Module.const_get (model_name.capitalize)
    data =  get_yaml model_name
    data[model_name.to_sym].each do |new_model|
      new_model[:pageant_id] = data[:pageant_id]
      model.create new_model
    end
  end
  
  def self.get_yaml (file)
    YAML.load_file "#{@@data_directory}#{file}.yml"
  end
  
  private_class_method :get_yaml, :seed_model
end