class Issue::Unknown < Issue
  def default_severity
    :warning
  end

  # Unknown issues are always stale because we only want to show them
  # to the user once.  If the same error occurs again, we'll create a new instance.
  def stale?
    true
  end
end
