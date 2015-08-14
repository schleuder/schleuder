class StandardError
  def message_with_backtrace
    "#{self.message}\n#{self.backtrace.join("\n")}\n"
  end
end
