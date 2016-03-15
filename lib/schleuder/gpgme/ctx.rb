module GPGME
  class Ctx
    def keyimport(*args)
      self.import_keys(*args)
      result = self.import_result
      result.imports.map(&:set_action)
      result
    end
  end
end
