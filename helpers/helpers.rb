module ApplicationHelper 
  def content_for(key, &block)
    @content ||= {}
    @content[key] = capture_haml(&block)
  end
  
  def content(key)
    @content && @content[key]
  end
  
  def json_status(code, reason)
    status code
    {
      :status => code,
      :reason => reason
    }.to_json
  end
    
  def render_page(view)
    if File.exist? ROOT_DIR + "/views/#{view}.haml" then
      content_type 'html'
      @view = view
      haml view.to_sym     
    else
      status 404
    end
  end


  
end