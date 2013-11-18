#Used to get data from the text files in the data directory
class DBSeeder
  @@data_directory = 'data/'

  def self.seed_mmue_2013

    Pageant.create long_name: 'Mr. and Ms. UE 2013', short_name: 'MMUE 2013',
      client: 'UE USC', client_contact: 'Karen Paguia',
      pageant_date: Date.new(2013, 9, 27), pageant_location: 'UE Theater'
    mmue_pageant = Pageant.last

    File.readlines(get_file_name('rounds')).each do |line|
      Round.create pageant_id: mmue_pageant.id, name: line.gsub("\n", "")
    end

    File.readlines(get_file_name('candidates')).each do |line|
      candidate_number, first_name, last_name, gender, short_description, 
        long_description, facial_body_location, body_photo_location = line.chomp.split(/s*\|\s*/)

      Candidate.create pageant_id: mmue_pageant.id, candidate_number: candidate_number, 
        first_name: first_name, last_name: last_name, gender: gender,
        short_description: short_description, long_description: long_description,
        facial_photo_location: facial_body_location, body_photo_location: body_photo_location
    end

    File.readlines(get_file_name('categories')).each do |line|
      chunks = line.gsub("\n", "").split("|")
      Category.create pageant_id: mmue_pageant.id, round_id: Round.all(name: chunks[4])[0].id,
        number: chunks[0],
        short_name: chunks[2],
        long_name: chunks[1],
        weight: chunks[3]
    end

    File.readlines(get_file_name('judges')).each do |line|
      chunks = line.gsub("\n", "").split("|")
      Judge.create pageant_id: mmue_pageant.id, number: chunks[0], name: chunks[1], assistant: chunks[2]
    end

    Pageant.activate(Pageant.first.id)
    Round.activate(Round.first.id)
    Category.activate(Round.first.id)

  end

  def self.seed_mmue_scores
    Category.all.each do |category|
      Judge.all.each do |judge|
        Candidate.all.each do |candidate|
          Score.new({
              pageant_id:  Pageant.first.id,
              judge_id: judge.id,
              category_id: category.id, 
              candidate_id: candidate.id,
              score: rand(75..100)
            }).save
        end
      end
    end
  end
  
#  Helper
  def self.get_file_name (file)
    "#{@@data_directory}#{file}.txt"
  end
  private_class_method :get_file_name 
end