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
  property :facial_photo_location, String, :default => lambda {|r, p| "#{r.candidate_number.to_s + r.gender.downcase}-face.jpg" }
  property :body_photo_location, String, :default => lambda {|r, p| "#{r.candidate_number.to_s + r.gender.downcase}-body.jpg" }

  belongs_to :pageant
  has n, :scores
end