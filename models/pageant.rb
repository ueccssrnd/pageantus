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
  
  def self.active
    self.first(is_active:true)
  end
  
  def start (server_address)
    if Pageant.starting?
      "#{Pageant.active.short_namename} with ID #{Pageant.active.id} is starting"
    else
      self.update(server_address: server_address, is_active: true)
    end
  end
  
  def self.stop
    self.first.update(is_active: false)
  end

  def backup (directory = '')
    file = File.new("#{directory}/scores-#{DateTime.now.strftime('backup-%Y-%m-%d-%H-%M-%S.txt')}", 'w')
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