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