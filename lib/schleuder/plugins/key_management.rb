module Schleuder
  module RequestPlugins
    def self.add_key(arguments, list, mail)

      if mail.has_attachments?
        results = self.import_keys_from_attachments(list, mail)
      else
        results = [self.import_key_from_body(list, mail)]
      end

      import_stati = results.compact.collect(&:imports).flatten

      if import_stati.blank?
        return I18n.t('plugins.key_management.no_imports')
      end

      out = []

      import_stati.each do |import_status|
        if import_status.action == 'error'
          out << I18n.t("plugins.key_management.key_import_status.error", fingerprint: import_status.fingerprint)
        else
          key = list.gpg.find_distinct_key(import_status.fingerprint)
          if key
            out << I18n.t("plugins.key_management.key_import_status.#{import_status.action}", key_oneline: key.oneline)
          end
        end
      end

      out.join("\n\n")
    end

    def self.delete_key(arguments, list, mail)
      if arguments.blank?
        return I18n.t(
          "plugins.key_management.delete_key_requires_arguments"
        )
      end

      arguments.map do |argument|
        keys = list.keys(argument)
        case keys.size
        when 0
          I18n.t("errors.no_match_for", input: argument)
        when 1
          begin
            keys.first.delete!
            I18n.t('plugins.key_management.deleted', key_string: keys.first.oneline)
          rescue GPGME::Error::Conflict
            I18n.t('plugins.key_management.not_deletable', key_string: keys.first.oneline)
          end
        else
          I18n.t('errors.too_many_matching_keys', {
              input: argument,
              key_strings: keys.map(&:to_s).join("\n")
            })
        end
      end.join("\n\n")
    end

    def self.list_keys(arguments, list, mail)
      args = Array(arguments.presence || '')
      args.map do |argument|
        # In this case it shall be allowed to match keys by arbitrary
        # sub-strings, therefore we use `list.gpg` directly to not have the
        # input filtered.
        list.gpg.keys(argument).map do |key|
          key.to_s
        end
      end.join("\n\n")
    end

    def self.get_key(arguments, list, mail)
      arguments.map do |argument|
        keys = list.keys(argument)
        if keys.blank?
          I18n.t("errors.no_match_for", input: argument)
        else
          result = [I18n.t('plugins.key_management.matching_keys_intro', input: argument)]
          keys.each do |key|
            atchm = Mail::Part.new
            atchm.body = key.armored
            atchm.content_type = 'application/pgp-keys'
            atchm.content_disposition = "attachment; filename=#{key.fingerprint}.asc"
            result << atchm
          end
          result.flatten
        end
      end
    end

    def self.fetch_key(arguments, list, mail)
      if arguments.blank?
        return I18n.t(
          "plugins.key_management.fetch_key_requires_arguments"
        )
      end

      arguments.map do |argument|
        list.fetch_keys(argument)
      end
    end

    # helper methods
    private

    def self.is_armored_key?(material)
      return false unless /^-----BEGIN PGP PUBLIC KEY BLOCK-----$/ =~ material
      return false unless /^-----END PGP PUBLIC KEY BLOCK-----$/ =~ material

      lines = material.split("\n").reject(&:empty?)
      # remove header
      lines.shift
      # remove tail
      lines.pop
      # verify the rest
      # TODO: verify length except for lasts lines?
      # headers according to https://tools.ietf.org/html/rfc4880#section-6.2
      lines.map do |line|
        /\A((comment|version|messageid|hash|charset):.*|[0-9a-z\/=+]+)\Z/i =~ line
      end.all?
    end

    def self.import_keys_from_attachments(list, mail)
      mail.attachments.map do |attachment|
        material = attachment.body.to_s

        list.import_key(material) if self.is_armored_key?(material)
      end
    end

    def self.import_key_from_body(list, mail)
      key_material = mail.first_plaintext_part.body.to_s

      list.import_key(key_material) if self.is_armored_key?(key_material)
    end
  end
end
