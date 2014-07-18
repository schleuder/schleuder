module Schleuder
  module Plugins
    def self.subscribe(arguments, list, mail)
      list.subscriptions.new email: arguments.first, fingerprint: arguments.last
    end
    alias_method :add_member, :subscribe

    # TODO: wasn't there a unsubscribe-keyword before, that behaved
    # differently? We should handle conflicting expectations.
    def self.unsubscribe(arguments, list, mail)
      with_split_args(arguments).each do |argument|
        list.subscriptions.where(email: arguments).delete
      end
    end
    alias_method :delete_member, :unsubscribe

    def self.list_subscriptions(arguments, list, mail)
      with_split_args(arguments).each do |argument|
        list.subscriptions.where(email: argument).map do |subscription|
          "#{subscription.email} #{subscription.fingerprint}"
        end
      end
    end
    alias_method :list_members, :list_subscriptions
    alias_method :list_subscribers, :list_subscriptions
  end
end

