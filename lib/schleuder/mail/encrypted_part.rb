module Mail                                                                                                                                            
  module Gpg                                                                                                                                           
    class EncryptedPart < Mail::Part                                                                                                                   
      alias_method :initialize_mailgpg, :initialize

      def initialize(cleartext_mail, options = {})
        if cleartext_mail.protected_headers_subject
          cleartext_mail.content_type_parameters['protected-headers'] = 'v1'                                                                       
        end
        initialize_mailgpg(cleartext_mail, options)
      end
    end
  end
end
