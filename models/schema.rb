##ORM and Models via Datamapper, SQLite database
DataMapper.setup(:default,  ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.rb")

module Activatable
  def active
    # Make this allow for multiple
    context = Module.const_get(name).all(is_active: true)
  end

  def is_starting?
    !active.nil?
  end

  def activate(id)
    if name == 'category'
      repository(:default).adapter.select("UPDATE CATEGORIES SET is_active = 't' WHERE id = ?", id)
    else
      Module.const_get(name).get(id).update(is_active: true)
    end    
  end

  def deactivate(id)
    Module.const_get(name).get(id).update(is_active: false)
  end

  def deactivate_all()
    Module.const_get(name).all().update(is_active: false)
  end
end

class Pageant
  include DataMapper::Resource
  extend Activatable
  DataMapper::Property.required(true)

  property :id, Serial
  property :is_active, Boolean, :default => false
  property :long_name, String, length: 10..255
  property :short_name, String,  length: 4..16
  property :round, Integer, :min => 1, :default => 1
  property :background_image, String, :default => 'backgrounds/black.jpg'
  property :message_title, String, :default => 'MARBLECAKE'
  property :message_data, String, :default => 'MARBLECAKE ALSO THE GAME'
  property :server_address, String, :default => '0.0.0.0'
  property :client, String
  property :client_contact, String
  property :pageant_location, String
  property :pageant_date, DateTime
  [:rounds, :candidates, :categories, :judges, :scores].each {|i|  has n, i}

  def backup

    file = File.new('data/scores-' + DateTime.now.strftime('backup-%Y-%m-%d-%H-%M-%S.txt'), 'w')

    Score.all.each do |score|
      file.write(score.to_json + "\n")
    end

  end

  def generate_top_5(gender='F')
    scores1 = Round.get(1).compute_scores(gender).collect {|score| score.to_h}
    scores1 = scores1.collect! do |score| 
      
      score[:average] = score.delete(:average)
      score.except(:gender, :score_list)
    end

    scores2 = Round.get(2).compute_scores(gender).collect {|score| score.to_h}
    scores2 = scores2.collect! do |score| 
      
      score[:average] = (1.25 * score.delete(:average)).round(3)
      score.except(:candidate_id, :gender, :score_list)
    end

    count = 0
    scores1.collect do |score|
      score[:final] = scores2[count][:average]
      score[:score] = (score[:average] * 0.2 + 0.8 * score[:final]).round(4)
      count = count + 1
    end

    
    scores1 = scores1.sort_by {|h| -h[:score]}

  end

  def candidates_in_top_5(gender='F')
    self.generate_top_5(gender).last(3).map do |score|
      Candidate.get(score[:candidate_id]).update(is_active: false)
    end
  end

end

class Round
  include DataMapper::Resource
  extend Activatable
  DataMapper::Property.required(true)

  property :id, Serial
  property :name, String
  property :is_active, Boolean, :default => false

  belongs_to :pageant
  has n, :categories


  def get_categories_for
    repository.adapter.select("
        SELECT DISTINCT categories.id, short_name
        FROM categories
        JOIN rounds
        ON rounds.id = categories.round_id
        WHERE rounds.id = ?
        ORDER BY categories.id
      ", self.id)
  end

  def compute_scores (gender='F')
    repository.adapter.select("
    SELECT candidate_id, candidate_number, name, 
            gender, short_description, 
            GROUP_CONCAT(round_score) AS score_list, 
            ROUND(SUM(average), 3) AS average
      FROM
            (
              SELECT DISTINCT outer_scores.candidate_id, 
              candidates.candidate_number,
              candidates.first_name || ' ' || candidates.last_name AS 'name',
              candidates.gender, 
              candidates.short_description,
              outer_scores.category_id,
            ROUND((
              SELECT AVG(score)
                  FROM scores AS inner_scores
                  WHERE inner_scores.category_id = outer_scores.category_id
                  AND inner_scores.candidate_id = outer_scores.candidate_id
            ), 2) AS round_score,
            (
                SELECT 
                (
                  SELECT AVG(score)
                  FROM scores AS inner_scores
                  WHERE inner_scores.category_id = outer_scores.category_id
                  AND inner_scores.candidate_id = outer_scores.candidate_id
                )
                * weight / 100
            ) AS average
            FROM scores outer_scores 
            JOIN candidates 
            ON candidates.id = outer_scores.candidate_id
            JOIN categories
            ON categories.id = outer_scores.category_id
            JOIN rounds
            ON categories.round_id = rounds.id
            WHERE round_id = ?
            AND gender = ?
            ORDER BY candidate_id
            ) 
    GROUP BY candidate_id", self.id, gender)
  end
end

class Category
  extend Activatable
  include DataMapper::Resource
  DataMapper::Property.required(true)

  property :id, Serial
  property :is_active, Boolean, :default => false
  property :is_ready, Boolean, :default => false
  property :number, Integer
  property :short_name, String, length: 3..20
  property :long_name, String
  property :weight, Decimal, precision: 10, scale: 4
  property :minimum_score, Decimal, :default => 75
  property :maximum_score, Decimal, :default => 100
  property :started_at, DateTime, :default => DateTime.now
  property :ended_at, DateTime, :default => DateTime.now

  belongs_to :pageant
  belongs_to :round
  has n, :scores

  # validates_with_method :check_uniqueness_of_category_number

  # Can't insert a score that has been inserted already
  # Can't insert a score that is not within the minimum and maximum values
  def check_uniqueness_of_category_number
    !(Category.all(pageant_id: self.pageant_id, number: self.number ).count > 0)
  end

  def toggle_submission(is_ready)
    Category.all.update(is_ready: false)
    self.update(is_ready: true) if (self.is_active && is_ready)
  end

  def submission_allowed?
    self.is_ready
  end

  def active?
    self.is_active
  end

  def get_judges_for
    repository.adapter.select("
        SELECT DISTINCT judges.assistant AS judge_name
        FROM judges
        JOIN scores
        ON scores.judge_id = judges.id
        WHERE scores.category_id = ?", self.id)
  end

  def compute_scores (gender='F')
    repository.adapter.select("
        SELECT DISTINCT candidates.id AS candidate_id, 
        candidates.candidate_number, 
        candidates.first_name || ' ' || candidates.last_name AS 'name',
        candidates.gender,
        candidates.short_description,
        candidates.long_description, 
        (
            SELECT GROUP_CONCAT(inner_scores.score) 
            FROM scores AS inner_scores
            WHERE inner_scores.candidate_id = outer_scores.candidate_id
                
                AND inner_scores.category_id = ?
            ORDER BY inner_scores.judge_id
        ) AS score_list,
        ROUND((
          SELECT AVG(inner_scores.score) 
            FROM scores AS inner_scores 
            WHERE inner_scores.category_id = ?
            AND inner_scores.candidate_id = outer_scores.candidate_id
        ), 2) AS average
        FROM scores outer_scores 
        JOIN candidates 
        ON candidates.id = outer_scores.candidate_id
        WHERE candidate_id IN
          (
            SELECT DISTINCT candidate_id FROM scores where category_id = ?
          )
        AND candidates.gender= ?", self.id, self.id, self.id, gender.capitalize)
  end

  def get_max(gender='F')
    self.compute_scores(gender).max_by {|score| score.average}
  end

end

class Candidate
  include DataMapper::Resource
  DataMapper::Property.required(true)
  
  property :id, Serial
  property :is_active, Boolean, :default => true
  property :candidate_number, String
  property :first_name, String, length: 2..255
  property :last_name, String, length: 2..255
  property :gender, String
  property :short_description, String, length: 3..8
  property :long_description, String, length: 16..255
  property :facial_photo_location, String, :default => 'rnd_face.jpg'
  property :body_photo_location, String, :default => 'rnd_body.jpg'

  belongs_to :pageant
  has n, :scores
end

class Judge
  include DataMapper::Resource
  DataMapper::Property.required(true)

  property :id, Serial
  property :number, String
  property :name, String, :default => "Judge"
  property :is_connected, Boolean, :default => false
  property :ip_address, String, :default => "none"
  property :assistant, String, :default => "Lance Boy"

  belongs_to :pageant
  has n, :scores
end

class Score 
  include DataMapper::Resource

  property :id, Serial
  property :score, Integer

  [:pageant, :candidate, :category, :judge].each {|i|  belongs_to i}

  validates_with_method :check_uniqueness_of_score

  # Can't insert a score that has been inserted already
  # Can't insert a score that is not within the minimum and maximum values

  def check_uniqueness_of_score
    !(Score.all(pageant_id: self.pageant_id, candidate_id: self.candidate_id, 
        category_id: self.category_id, judge_id: self.judge_id).count > 0) &&
      self.score.between?(Category.get(self.category_id).minimum_score, Category.get(self.category_id).maximum_score)
  end
end

DataMapper.auto_upgrade!
# DataMapper.auto_migrate!