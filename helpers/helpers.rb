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
    content 'html'
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