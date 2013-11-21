require File.join(File.dirname(__FILE__), 'environment')

#configure production statis cture cache enabled true

class Pageantus < Sinatra::Base
  helpers ApplicationHelper

  enable :sessions
  set :root, File.dirname(__FILE__)
  set :protection, :except => [:http_origin, :remote_token]
  set :public_folder, File.dirname(__FILE__) +  '/public'
  set :session_secret, 'super sectero'
  set :environment, :development
  
  DataMapper.finalize
  DataMapper.auto_upgrade!

 
  ##Sinatra REST Routes

  before  do
    @models = %w{pageant round category candidate judge score setting}
    @to_pass = params[:data] || params
    #    response['Access-Control-Allow-Origin'] = '*' #this is dangerous! haha
    #    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
  end

  # Routes for views: homepage, if logged in then go to admin or client. 

  get '/' do
#    binding.pry
    if session[:user_id]
      puts session[:user_id]
      render_page 'judge'
    else
      render_page 'login'  
    end
  end
  
  get '/test' do
    content_type 'json'
    Pageant.first.long_name
  end

  #  get '/backup' do
  #    Pageant.active.backup
  #    'yey'.to_json
  #  end
  #
  post '/login' do
    check_if_admin(params[:username], params[:assistant])
    check_if_judge(params[:username], params[:assistant], request.ip)
    redirect '/'
  end
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
  get '/logout' do
    session.clear
    redirect '/'
  end
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
  not_found do
    #      check if request is json or not
    json_status 404, 'Battlecruiser not in transit'
  end
  #
  #  error do
  #    json_status 500, env['sinatra.error'].message
  #  end

end



# begin
# => https://github.com/bbatsov/ruby-style-guide

# end