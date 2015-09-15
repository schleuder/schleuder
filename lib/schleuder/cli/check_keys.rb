module Schleuder
  module Cli
    class CheckKeys < Thor
      default_task :check_keys

      desc 'check_keys', "This scripts checks all lists for expiring or unusable keys. It should be run once a week, e.g. from cron"
      def check_keys
        now = Time.now
        checkdate = now + (60 * 60 * 24 * 14) # two weeks

        unusable = []
        expiring = []

        Schleuder::List.all.each do |list|
          I18n.locale = list.language

          list.keys.each do |key|
            expiry = key.subkeys.first.expires
            if expiry && expiry > now && expiry < checkdate
              # key expires in the near future
              expdays = ((exp - now)/86400).to_i
              expiring << [key, expdays]
            end

            if key.trust
              unusable << [key, key.trust]
            end
          end

          msg = ''
          expiring.each do |key,days|
            msg << I18n.t('key_expires', {
                              days: days,
                              fingerprint: key.fingerprint,
                              email: key.email
                          })
          end

          unusable.each do |key,trust|
            msg << I18n.t('key_unusable', {
                              trust: Array(trust).join(', '),
                              fingerprint: key.fingerprint,
                              email: key.email
                          })
          end

          if msg.present?
            text = "#{I18n.t('check_keys_intro', email: list.email)}\n\n#{msg}"
            list.logger.notify_admin(text, nil, I18n.t('check_keys'))
          end
        end
      end
    end
  end
end

