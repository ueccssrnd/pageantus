ENV['RACK_ENV'] = 'test'

require_relative 'hello_sinatra'
require 'rspec'
require 'rack/test'
require 'factory_girl'

describe Pageant do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	before (:all) do
		DBSeeder.seed_sample_pageant if Pageant.all.count == 0

		@correct_pageant_data =  {:long_name => 'Mr. and Ms. UE 2013', 
						:short_name => 'MMUE 2013',
						:client => 'UE USC',
						:client_contact => 'Karen Paguia',
						:pageant_date => DateTime.now,
						:pageant_location => 'UE Theater'}
		@wrong_pageant_data = @correct_pageant_data.clone.tap{|x| x.delete(:short_name)}

	end

	describe "is created" do

		it "if you pass in valid data" do
		pageant_count = Pageant.all.length
		# count = Pageant.all.count
		post '/pageant', data: @correct_pageant_data
		Pageant.last[:active].should be_false 
		#test that the pageant is not active
		#test that the date created is today
		#continue this test: expect {correct_pageant_data.save}.to change {Pageant.count}.by(1)
		last_response.status.should eq 201
		Pageant.all.length.should eq pageant_count+1
		last_response.body.should include 'Mr. and Ms. UE 2013'
		end

		it "should not be created if the hash is missing" do
		post '/pageant', @wrong_pageant_data
		last_response.status.should eq 412
		end
	end

	describe 'is activated' do
		it "if activation is valid and nothing is activated already" do
			post '/pageant/activate', :id => Pageant.first[:id]
			Pageant.is_starting?.should eq(true)
			last_response.status.should eq 201
		end

		it "should not be activated if there is another pageant currently activated" do
			post '/pageant/activate', :id => Pageant.first[:id]
			Pageant.all(:is_active => true).count.should eq 1
			last_response.status.should eq 412
		end

		it "could be deactivated if you pass in the activation" do
			post '/pageant/deactivate', :id => Pageant.first[:id]
			Pageant.is_starting?.should eq(false)
			last_response.status.should eq 201
		end
	end

	describe 'has candidates' do
		before (:all) do
		@correct_candidate_data =  {
						:pageant_id => Pageant.first.id,
						:candidate_number => '1', 
						:first_name => 'Karen',
						:last_name => 'Paguia',
						:gender => 'F',
						:short_description => 'UE CBA',
						:long_description => 'UE College of Business Administration'}
		@wrong_candidate_data = @correct_candidate_data.clone.tap{|x| x.delete(:first_name)}
		end

		it 'that can be accessed' do
			get '/candidate', {:gender => 'F'}
		end




		it 'who can be created if everything is valid' do
			candidate_count = Candidate.all.length
			post '/candidate', @correct_candidate_data
			Candidate.all.length.should eq candidate_count+1
			last_response.status.should eq 201
			# last_response.reason.should eq 'candidate'
			
		end

		it 'who won\'t be created if everything is not' do
			candidate_count = Candidate.all.length
			post '/candidate', @wrong_candidate_data
			Candidate.all.length.should eq candidate_count
			last_response.status.should eq 412
		end

		it 'who can\'t be created if same number' do
			candidate_count = Candidate.all.length
			post '/candidate', @wrong_candidate_data
			Candidate.all.length.should eq candidate_count
			last_response.status.should eq 412
		end

		it 'who could be destroyed' do
			delete '/candidate', id: Candidate.last.id
			last_response.status.should eq 200
		end

		it 'who could be destroyed cat' do
			delete '/category', id: Category.last.id
			last_response.status.should eq 200
		end

		it 'who could be destroyed round' do
			delete '/round', id: Round.last.id
			last_response.status.should eq 200
		end
	end

	describe 'has categories' do
		before (:all) do

			@correct_category_data =  {
				pageant_id: Pageant.first.id,
				round_id: Round.first.id,
				number: 5,
				short_name: 'Test', 
				long_name: 'Testing thing',
				weight: 20}
		@wrong_category_data = @correct_category_data.clone.tap{|x| x.delete(:short_name)}

		end


		it '.post valid' do
			category_count = Category.all.length
			post '/category', @correct_category_data
			Category.all.length.should eq category_count+1
			last_response.status.should eq 201
		end		

		it '.post invalid number' do
			category_count = Category.all.length
			post '/category', @correct_category_data
			Category.all.length.should eq category_count
			last_response.status.should eq 412
		end

		it '.post invalid' do
			category_count = Category.all.length
			post '/category', @wrong_category_data
			Category.all.length.should eq category_count
			last_response.status.should eq 412
		end

		it 'should be mass insertable' do
			pending
		end

		it 'should be deletable' do
			delete '/category', id: Category.last.id
			last_response.status.should eq 200
		end

		it 'should not be deletable if pageant is running' do
			pending
		end


	end

	describe 'has judges' do
		before (:all) do
		@correct_judge_data =  {
						:pageant_id => Pageant.first.id,
						:number => '1', 
						:name => 'Mojacko'}
		@wrong_judge_data = @correct_judge_data.clone.tap{|x| x.delete(:number)}
		end

		it '.post valid' do
			judge_count = Judge.all.length
			post '/judge', @correct_judge_data
			Judge.all.length.should eq judge_count+1
			last_response.status.should eq 201
			# last_response.reason.should eq 'candidate'
			
		end

		it 'who won\'t be created if everything is not' do
			
			judge_count = Judge.all.length
			post '/judge', @wrong_judge_data
			Judge.all.length.should eq judge_count
			last_response.status.should eq 412
		end

		it 'who could be destroyed' do
			delete '/judge', id: Judge.last.id
			last_response.status.should eq 200
		end
	end


	describe 'has scores' do
		before (:all) do
			post '/pageant/activate', :id => Pageant.first[:id]

			@negative_score_data =  {
						:pageant_id => Pageant.first.id,
						:judge_id => Judge.first.id,
						:category_id => Category.first.id, 
						:candidate_id => Candidate.first.id,
						:score => -10}

			@correct_score_data =  {
						:pageant_id => Pageant.first.id,
						:judge_id => Judge.first.id,
						:category_id => Category.first.id, 
						:candidate_id => Candidate.first.id,
						:score => 10}

			@mass_score_data =
				[{
						:pageant_id => Pageant.first.id,
						:judge_id => Judge.first.id,
						:category_id => Category.first.id, 
						:candidate_id => 2,
						:score => 10},
						{
						:pageant_id => Pageant.first.id,
						:judge_id => Judge.first.id,
						:category_id => Category.first.id, 
						:candidate_id => 3,
						:score => 10}
					]


		end

		it 'that cannot be inserted if it is not in the proper range' do
			score_count = Score.all.length
			post '/score', @negative_score_data
			Score.all.length.should eq score_count
		end

		it 'that can be inserted by a judge if a pageant is active' do
			score_count = Score.all.length
			post '/score', @correct_score_data
			Score.all.length.should eq score_count+1
		end

		it 'that can be mass inserted' do
			score_count = Score.all.length
			post '/score', data: @mass_score_data
			Score.all.length.should eq score_count+2
		end

		it 'cannot be duplicated if it has been sent' do
			score_count = Score.all.length
			post '/score', @correct_score_data 
				# expect { post '/score', @correct_score_data }.to raise_error
				Score.all.length.should eq score_count
		end


		# it 'that cannot be inserted by a judge if a pageant is not active' do
		# 	post '/pageant/deactivate', :id => Pageant.first[:id]
		# 	Pageant.active.count.should eq 0
		# end



		it 'can be deleted' do
			3. times {delete '/score', id: Score.last.id}
			last_response.status.should eq 200
		end




	end

	describe 'can be edited' do
		it "if you pass in valid variables" do
			put '/pageant', {:id => Pageant.first[:id], 
						:short_name => 'MMCCS2 2012'}

			last_response.status.should eq 201
			Pageant.first[:short_name].should eq 'MMCCS2 2012'

		end
	end

	describe 'can compute scores' do
		before (:all) do
			post '/pageant/activate', :id => Pageant.first[:id]

			round_name = 'Preliminary'

			if Pageant.active.rounds(name: round_name).categories.scores.count == 0

				(1..4).each do |h|
					(1..4).each do |i|
						(1..9).each do |j|
							Score.create(pageant_id: Pageant.active.id,
							category_id: h,
							judge_id: i,
							candidate_id: j,
							score: Random.rand(70..100))
						end
					end
				end


			end

		end

		it 'can\'t compute score if bad short name or number' do
			get '/compute/BAD_NAME'
			last_response.status.should eq 412
		end

		it 'can compute if valid' do
			get '/compute/PCat2'
			last_response.status.should eq 200
		end


		it 'you cannot compete for score if the pageant is inactive' do
			pending
		end

		it 'can compute round scores' do
			get '/compute/round/Preliminary'
			last_response.status.should eq 200

		end

		it 'should be right result mathematically' do

		end

		it 'should be solved even if judges are not complete' do

		end

	end


	describe 'is destroyed' do
		it "if you pass in valid variables" do
			
			delete '/pageant', :id => Pageant.last[:id]
			last_response.status.should eq 200
		end

		it 'destroy one round and one category first' do
			pending
		end

	end






	

	

# 	it "could be activated if the person wishe?

# 	# correct_pageant_data = {:name => 'University of the East Manila', 
# 	# 					:short_name => 'Mr. and Ms. UE 2013',
# 	# 					:client => 	'UE USC',
# 	# 					:client_contact => 'Karen Paguia',
# 	# 					:pageant_date => DateTime.now,
# 	# 					:pageant_location => 'UE Theater'}

# 	it "candidates should be created if parameters are valid" do
# count = Candidate

# 	end



	
end