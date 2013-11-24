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
  
  def connect(assistant, ip_address)
    self.update(ip_address: ip_address, assistant: assistant, is_connected: true)
  end
  
  def disconnect
    self.update(is_connected: false)
  end
end