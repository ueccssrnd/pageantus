ENV['RACK_ENV'] = 'test'

require_relative '../hello_sinatra'
require 'rspec'
require 'rack/test'
require 'factory_girl'

describe Pageant do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	before (:all) do
		@sample_data =  {:name => 'Mr. and Ms. UE 2013', 
						:short_name => 'MMUE 2013',
						:client => 'UE USC',
						:client_contact => 'Karen Paguia',
						:pageant_date => DateTime.now,
						:pageant_location => 'UE Theater'}
	end

	describe "is created" do

		it "if you pass in valid data" do
		# Pageant.all.length should eq 0
		# count = Pageant.all.count
		post '/pageant', @sample_data
		#test that the pageant is not active
		#test that the date created is today
		#continue this test: expect {sample_data.save}.to change {Pageant.count}.by(1)
		last_response.status.should eq 201
		# Pageant.all.count.should eq (count+1)
		last_response.body.should include 'Mr. and Ms. UE 2013'
		end

		# it "should not be created if the hash is missing" do
		# incomplete_data = sample_data.dup.delete :short_name
		# post '/pageant', incomplete_data
		# last_response.status.should eq 412
		# end



	end

	describe 'is activated' do
		it "could be activated if you pass in the activation" do
			post '/pageant/activate', :id => 2
			puts Pageant.all.count
			puts Pageant.all(:is_active => true)
			puts Pageant.all(:is_active => true).count 
			last_response.status.should eq 201
		end

		it "should not be activated if there is another pageant currently activated" do
			post '/pageant/activate', :id => Pageant.first.id
			last_response.status.should eq 412
			# puts Pageant.active.count
			# Pageant.active.count should eq 1
		end

		it "could be deactivated if you pass in the activation" do
			post '/pageant/deactivate', :id => 2
			last_response.status.should eq 201
		end
	end






	

	

# 	it "could be activated if the person wishe?

# 	# sample_data = {:name => 'University of the East Manila', 
# 	# 					:short_name => 'Mr. and Ms. UE 2013',
# 	# 					:client => 	'UE USC',
# 	# 					:client_contact => 'Karen Paguia',
# 	# 					:pageant_date => DateTime.now,
# 	# 					:pageant_location => 'UE Theater'}

# 	it "candidates should be created if parameters are valid" do
# count = Candidate

# 	end



	
end