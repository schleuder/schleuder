class StandardError
  def message_with_backtrace
    "#{message}\n#{self.backtrace.join("\n")}\n"
  end
end
