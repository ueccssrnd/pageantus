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