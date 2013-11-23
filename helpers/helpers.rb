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


  def check_permissions
    if session[:admin]
      if Pageant.starting?
        Pageant.active.update(server_address: request.env['REMOTE_ADDR'])
        @pageant = Pageant.active
      end
      render_page 'admin'
    elsif session[:user_id]
      render_page 'judge'
    else
      render_page 'login'
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