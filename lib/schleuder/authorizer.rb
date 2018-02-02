module Schleuder
  class Authorizer
    attr_reader :account

    def initialize(account)
      @policies = {}
      @policy_scopes = {}
      @account = account
    end

    def authorize(resource, action)
      return nil if resource == nil
      action = action.to_s
      action << '?' unless action.last == '?'
      policy(resource).public_send(action)
    end

    def scoped(klass)
      policy_scope(klass)
    end

    private

    def policy(resource)
      @policies[resource] ||= find_policy(resource)
    end

    def find_policy(resource)
      find_policy_class(resource).new(account, resource)
    end

    def find_policy_class(resource)
      klass_name = infer_class_name(resource)
      "AuthorizerPolicies::#{klass_name}Policy".constantize
    rescue NameError
      raise "No policy-class found for #{resource.inspect}"
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

    def infer_class_name(resource)
      if resource.respond_to?(:model_name)
        resource.model_name
      elsif resource.class.respond_to?(:model_name)
        resource.class.model_name
      elsif resource.is_a?(Class)
        resource
      elsif resource.is_a?(Symbol)
        resource.to_s.camelize
      else
        resource.class
      end.to_s.split('::').last
    end
  end
end
