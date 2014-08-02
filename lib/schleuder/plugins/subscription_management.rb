module Schleuder
  module Plugins
    def self.subscribe(arguments, list, mail)
      sub = list.subscriptions.new(email: arguments.first, fingerprint: arguments.last)
      "Subscribed:\n\n#{sub.email} #{sub.fingerprint}"
    end

    def self.add_member(*args)
      self.subscribe(*args)
    end

    # TODO: wasn't there a unsubscribe-keyword before, that behaved
    # differently? We should handle conflicting expectations.
    def self.unsubscribe(arguments, list, mail)
      arguments.each do |argument|
        if sub = list.subscriptions.where(email: arguments).delete
          "#{sub} was unsubscribed from #{list}"
        else
          "Unsubscribing #{sub} from #{list} failed!"
        end
      end
    end

    def self.delete_member(*args)
      self.unsubscribe(*args)
    end

    def self.list_subscriptions(arguments, list, mail)
      out = "List of subscriptions:\n\n"

      subs = if arguments.blank?
                list.subscriptions.all.to_a
             else
               arguments.map do |argument|
                 list.subscriptions.where("email like ?", "%#{argument}%").to_a
               end.flatten
             end

      out << subs.map do |subscription|
        "#{subscription.email} #{subscription.fingerprint}"
      end.join("\n")
    end

    def self.list_members(*args)
      self.list_subscriptions(*args)
    end

    def self.list_subscribers(*args)
      self.list_subscriptions(*args)
    end
  end
end

