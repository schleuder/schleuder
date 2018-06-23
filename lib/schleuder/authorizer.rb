module Schleuder
  class Authorizer
    attr_reader :account

    def initialize(account)
      @policies = {}
      @policy_scopes = {}
      @account = account
    end

    def authorize(thing, action)
      return nil if thing == nil
      action = action.to_s
      action << '?' unless action.last == '?'
      policy(thing).public_send(action)
    end

    def lists
      scoped(List)
    end

    def subscriptions
      scoped(Subscription)
    end

    def scoped(klass)
      policy_scope(klass)
    end


    private
    

    def policy(thing)
      @policies[thing] ||= find_policy(thing)
    end

    def find_policy(thing)
      find_policy_class(thing).new(account, thing)
    end

    def find_policy_class(thing)
      klass_name = infer_class_name(thing)
      "AuthorizerPolicies::#{klass_name}Policy".constantize
    rescue NameError
      raise "No policy-class found for #{thing.inspect}"
    end

    def policy_scope(klass)
      @policy_scopes[klass] ||= find_policy_scope(klass).resolve
    end

    def find_policy_scope(klass)
      find_policy_scope_class(klass).new(account)
    end

    def find_policy_scope_class(klass)
      class_name = find_policy_class(klass)
      if class_name
        class_name::Scope
      end
    end

    def infer_class_name(thing)
      if thing.respond_to?(:model_name)
        thing.model_name
      elsif thing.class.respond_to?(:model_name)
        thing.class.model_name
      elsif thing.is_a?(Class)
        thing
      elsif thing.is_a?(Symbol)
        thing.to_s.camelize
      else
        thing.class
      end.to_s.split('::').last
    end
  end
end
