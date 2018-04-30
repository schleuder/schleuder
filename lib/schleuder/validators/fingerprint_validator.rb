class FingerprintValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A[A-F0-9]{32,}\z/
      record.errors[attribute] << (options[:message] || I18n.t("errors.invalid_fingerprint"))
    end
  end
end
