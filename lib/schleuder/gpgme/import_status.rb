module GPGME
  class ImportStatus
    def action
      case status
      when 0 then "unchanged"
      when 1 then "imported"
      else "updated"
      end
    end
  end
end
