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