require 'sinatra/base'
require 'data_mapper'
Dir[File.dirname(__FILE__) + './models/*.rb'].each {|file| require file }

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

class Pageantus < Sinatra::Base

  enable :sessions
  set :root, File.dirname(__FILE__)
  set :protection, :except => [:http_origin, :remote_token]
  set :public_folder, File.dirname(__FILE__) +  '/public'
  set :session_secret, 'super sectero'
  set :environment, :production
  set :haml, { :format => :html5 }

  helpers do
    def json_status(code, reason)
      status code
      {
        :status => code,
        :reason => reason
      }.to_json
    end

    def check_permissions
      content_type 'html'
      if session[:admin]
        Pageant.active.update(server_address: request.env['REMOTE_ADDR'])
        @pageant = Pageant.active[0]
        erb :'admin.html'
      elsif session[:user_id]
        erb :'judge.html'
      else
        erb :'login.html'
      end
    end
    
    def check_if_admin(username ='', password = '')
      session[:admin] ||= true if (username == 'admin' && Digest::SHA1.hexdigest(password) == '75dce6d956d253730fe01071d9104da3f378a0e8')
    end

    def check_if_judge(username, assistant, ip_address)
      judge = Judge.all(name: username)

      if judge.length == 1
        judge[0].update(ip_address: ip_address, 
          assistant: assistant, is_connected: true)
        session[:user_id] = Judge.all(name: username)[0].id
      else
        redirect '/'
      end 
    end

  end

  ##Sinatra REST Routes

  before  do
    @models = %w{pageant round category candidate judge score setting}
    # check content type
#    content_type :json
    @to_pass = params[:data] || params
#    response['Access-Control-Allow-Origin'] = '*' #this is dangerous! haha
#    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
  end

  # Routes for views: homepage, if logged in then go to admin or client. 

  get '/' do
    content_type 'html'
    haml :index
    #    haml :layout
    #    "haml"
    #    check_permissions
  end

#  get '/backup' do
#    Pageant.active.backup
#    'yey'.to_json
#  end
#
#  post '/login' do
#    check_if_admin(params[:username], params[:assistant])
#    check_if_judge(params[:username], params[:assistant], request.ip)
#    redirect '/'
#  end
#
#  get '/old' do
#    content_type 'html'
#    erb :'adminold.html'
#  end
#
#  get '/projector' do
#    content_type 'html'
#    erb :'projector.html'
#  end
#
#  get '/top5' do
#    content_type 'html'
#    erb :'top5.html'
#  end
#
#  get '/logout' do
#    session.clear
#    redirect '/'
#  end
#
#  get '/session' do
#    session[:user_id].to_json
#  end
#
#  get '/time' do
#    current_time = Time.now
#    {time: current_time.strftime('%I:%M'), date: current_time.strftime('%A, %B %d, %Y'), meridian: current_time.strftime('%p')}.to_json
#  end
#
#  post '/message/?' do
#    Pageant.active.update(message_title: params[:title], message_data: params[:message_data])
#  end
#
#  get '/message' do
#    {title: Pageant.active.message_title, message: Pageant.active.message_data}.to_json
#  end
#
#  # Edit this to have it not by URL
#  put '/activate/:model/:id/?' do
#    model_class = Module.const_get(params[:captures].first.capitalize)
#  
#    model_class.deactivate_all
#
#    if model_class.activate(params[:id])
#      json_status 200, 'good'
#      model_class.active.to_json
#    else
#      json_status 412, 'fail'
#    end
#
#  end
#
#  get '/active/:model/?' do
#
#    if @models.include? params[:captures].first
#      model_class = Module.const_get(params[:captures].first.capitalize)
#      model_class.active.to_json
#    else
#      json_status 412, 'fail'
#    end
#  end
#
#  get '/submit' do
#    Category.active.is_ready.to_json
#    # Category.get(1).is_ready.to_json
#  end
#
#  post '/submit' do
#    JSON.parse(params[:scores]).each do |new_score|
#      # new_score.each do |inner_score|
#      Score.new({
#          score: new_score["score"],
#          pageant_id: Pageant.active.id,
#          candidate_id: new_score["candidate_id"],
#          judge_id: new_score["judge_id"],
#          category_id: new_score["category_id"]
#        }).save
#      # end
#    end
#    JSON.parse(params[:scores]).inspect.to_json
#  end
#
#  # Set if pwede na mag-pass
#  put '/submit' do
#    if Category.get(params[:id]).toggle_submission(params[:is_ready])
#      Category.active.to_json
#    else
#      json_status 412, 'fail'
#    end
#  end
#
#  class Report
#    def self.generate_category_score(category_id)
#      category = Category.get(category_id)
#      judges = category.get_judges_for
#    
#      pdf = Prawn::Document.new(:page_size => 'A4')
#    
#      pdf.text Pageant.active.long_name, align: :center, size: 24, leading: 12
#      pdf.text "Category Scores: #{category.long_name}", :align => :center, size: 18, leading: 6
#
#      title = {number: '#', name: 'Name', college: 'College'}
#      judges.each_with_index {|judge, index| title[:"#{index}"] = judge[0,3]}
#      title[:average] = 'Ave'
#
#      ['F', 'M'].each do |gender|
#        scores = category.compute_scores(gender).collect {|score| score.to_h}
#        scores = scores.collect! do |score|
#          score[:score_list].split(",").each_with_index {|indiv, index| score[:"#{judges[index]}"] = indiv }
#          score[:average] = score.delete(:average)
#          score.except(:candidate_id, :gender, :long_description, :score_list)
#        end
#
#        scores.unshift(title)
#        pdf.text gender == 'F' ? "Female:" : "Male:", size: 14, leading: 5
#        pdf.table(scores.collect {|x| x.values }, :width => 531, :column_widths => [24, 188])
#        pdf.move_down 10
#      end
#
#      ['F', 'M'].each do |gender|
#        max_score = category.get_max(gender).to_h
#        pdf.text (max_score[:gender] == 'F' ? "Female: " : "Male: ") + max_score[:name] + " " + max_score[:average].to_s, :align => :center, size: 18, leading: 6
#      end
#      pdf.render
#    end
#  end
#
#  get '/report/category/:id/?' do
#    content_type 'application/pdf'
#    Report.generate_category_score(params[:id])
#  end
#
#
#
#  get '/report/round/:id/?' do
#    round = Round.get(params[:id])
#    categories = round.get_categories_for
#
#    content_type 'application/pdf'
#    pdf = Prawn::Document.new(:page_size => 'A4') 
#    pdf.text Pageant.active.long_name, align: :center, size: 24, leading: 12
#    pdf.text "Round Scores: #{round.name}", :align => :center, size: 18, leading: 6
#
#    title = {number: '#', name: 'Name', college: 'College'}
#    categories.each_with_index {|judge, index| title[:"#{index}"] = judge[:short_name]}
#    title[:average] = 'Ave'
#
#    ['F', 'M'].each do |gender|
#      scores = round.compute_scores(gender).collect {|score| score.to_h}
#      scores = scores.collect! do |score| 
#    
#        score[:score_list].split(",").each_with_index {|indiv, index| score[:"#{categories[index][:short_name]}"] = indiv }
#        score[:average] = score.delete(:average)
#        score[:average] = score[:average] * 1.25 if round.id == 2
#        score[:average] = score[:average].round(2)
#        score.except(:candidate_id, :gender, :score_list)
#      end
#      scores.unshift(title)
#      pdf.text gender == 'F' ? "Female:" : "Male:", size: 14, leading: 5
#      pdf.table(scores.collect {|x| x.values }, :width => 531, :column_widths => [24, 188])
#      pdf.move_down 10
#    end
#    pdf.render
#  end
#
#  get '/report/top5/?' do
#    content_type 'application/pdf'
#    pdf = Prawn::Document.new(:page_size => 'A4') 
#    pdf.text Pageant.active.long_name, align: :center, size: 24, leading: 12
#    pdf.text "Prepageant + Coronation Scores", :align => :center, size: 18, leading: 6
#
#    ['F', 'M'].each do |gender|
#      title = {number: '#', name: 'Name', college: 'College', 
#        prepageant: 'Prepageant', coronation: 'Coronation', final: 'Final'}
#
#      scores1 = Pageant.active.generate_top_5(gender)
#      pdf.move_down 10
#      pdf.text gender == 'F' ? "Female:" : "Male:", size: 14, leading: 5
#      scores1.unshift(title)
#      pdf.table( scores1.collect {|x| x.except(:candidate_id).values }, :width => 531, :column_widths => [24, 188])
#
#      Pageant.active.candidates_in_top_5(gender)
#    end
#    pdf.render
#  end
#
#  get '/score/category/:gender' do
#    Category.active.compute_scores(params[:gender]).collect{|x| x.to_h.except(:gender, :score_list)}.to_json
#  end
#
#
#  get '/:model/?' do
#    check_if_admin
#
#    if @models.include? params[:captures].first
#      model_class = Module.const_get(params[:captures].first.capitalize)
#
#      model_class.all(@to_pass).to_json
#
#    else
#      json_status 412, 'fail'
#    end
#  end
#
#  post '/:model/?' do
#
#    if @models.include? params[:captures].first
#      model_class = Module.const_get(params[:captures].first.capitalize)
#
#
#      # If single object turn into an array then map a function over it 
#      ([@to_pass].flatten).map do |item|
#
#        if model_class.new(item).save
#          json_status 201, model_class.last.to_json
#          model_class.last.to_json
#        else
#          json_status 412, 'fail'
#        end
#
#
#      end
#
#    else
#      json_status 412, 'fail'
#    end
#  end
#
#  put '/:model/?' do
#
#    if @models.include? params[:captures].first
#      model_class = Module.const_get(params[:captures].first.capitalize)
#
#      @to_pass[:id] ||= model_class.active.id
#
#      if model_class.get(@to_pass[:id]).update(@to_pass)
#        ((model_class.is_a? Activatable) && !Category.active.nil? && model_class.active.to_json) || model_class.last.to_json
#      else
#        json_status 412, 'fail'
#      end
#    else
#      json_status 412, 'fail'
#    end
#  end
#
#
#  delete '/:model/?' do
#
#    if @models.include? params[:captures].first
#
#      model_class = Module.const_get(params[:captures].first.capitalize)
#
#
#      if model_class.get(@to_pass[:id]).destroy
#        json_status 200, model_class.last.to_json
#        model_class.last.to_json
#      else
#        json_status 412, 'fail'
#      end
#    else
#      json_status 412, 'fail'
#    end
#  end #delete route
#  
#  not_found do
#    json_status 404, 'Battlecruiser not in transit'
#  end
#
#  error do
#    json_status 500, env['sinatra.error'].message
#  end

end



# begin
# => https://github.com/bbatsov/ruby-style-guide

# end