module Activatable
  def active
    Module.const_get(name).all(is_active: true)
  end

  def starting?
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