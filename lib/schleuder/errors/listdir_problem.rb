module Schleuder
  module Errors
    class ListdirProblem < Base
      def initialize(dir, problem)
        @dir = dir
        @problem = problem
      end

      def message
        problem = t("errors.listdir_problem.#{@problem}")
        t('errors.listdir_problem.message', dir: @dir, problem: problem)
      end
    end
  end
end

