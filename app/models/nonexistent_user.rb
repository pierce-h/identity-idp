class NonexistentUser
  def uuid
    'nonexistent-uuid'
  end

  def role
    'nonexistent'
  end

  def confirmed?
    false
  end

  def persisted?
    false
  end
end
