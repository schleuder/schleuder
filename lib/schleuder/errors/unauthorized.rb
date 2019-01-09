module Schleuder
  module Errors
    class Unauthorized < Base
      def initialize(resource=nil)
        owner_email = case resource
          when List
            resource.owner_address
          when Subscription, GPGME::Key
            resource.list.owner_address
          else
            # Shouldn't happen, but who knows what life brings...
            'LISTNAME-owner@DOMAIN'
          end

        super t('errors.unauthorized', list_owner_email: owner_email)
      end
    end
  end
end

