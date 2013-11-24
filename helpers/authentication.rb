module AuthenticationHelper
  def check_permissions
    case session[:level]
    when 'admin'
      if Pageant.starting?
        @pageant = Pageant.active
      end
      render_page 'admin'
    when 'judge'
      render_page 'judge'
    else
      render_page 'login'
    end
  end
    
  def check_if_admin(username ='', password = '')
    session[:level] ||= 'admin' if (username == 'admin' && Digest::SHA1.hexdigest(password) == '75dce6d956d253730fe01071d9104da3f378a0e8')
  end

  def check_if_judge(username, assistant, ip_address)
    judge = Judge.first(name: username)
    unless judge.nil?
      judge.connect(assistant, ip_address)
      session[:level] = 'judge'
      session[:user_id] =judge.id
    end 
  end
end