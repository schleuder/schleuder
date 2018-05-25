module Schleuder
  module Errors
    class ListdirProblem < Base
      def initialize(dir, problem)
        problem = t("errors.listdir_problem.#{problem}")
        super t('errors.listdir_problem.message', dir: dir, problem: problem)
      end
    end
  end
end

