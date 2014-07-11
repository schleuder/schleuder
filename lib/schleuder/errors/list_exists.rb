class ListExists < StandardError
  def initialize(listname)
    @listname = listname
  end

  def message
    # TODO: i18n
    "List with name '%s' already present."
  end

  def to_s
    message % @listname
  end
end

