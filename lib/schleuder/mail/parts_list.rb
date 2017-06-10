module Mail
  class PartsList
    # Disable sorting of mime-parts completely.
    # Can't be done during runtime on the body-instance (`body#set_sort_order`)
    # because MailGpg exchanges the body-instances when encrypting/signing.
    def sort!(*args)
    end
  end
end
