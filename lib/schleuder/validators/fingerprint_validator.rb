class FingerprintValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A[a-f0-9]+\z/i
      record.errors[attribute] << (options[:message] || I18n.t("errors.invalid_fingerprint"))
    end
  end
end
