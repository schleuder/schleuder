class FileNotFound < StandardError
  def initialize(filename)
    @filename = filename
  end

  def message
    "File not found: '%s'."
  end

  def to_s
    message % @filename
  end
end
