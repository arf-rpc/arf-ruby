# frozen_string_literal: true

module ContactsImpl
  include Contacts

  class ContactsState
    attr_accessor :contacts

    def initialize
      @contacts = {}
      @id_lock = Monitor.new
      @contacts_lock = Monitor.new
      @id = 0
    end

    def by_id(id) = @contacts_lock.synchronize { @contacts[id] }

    def get_or_initialize(id)
      if id.nil?
        @id_lock.synchronize do
          id = @id + 1
          @id += 1
        end
      end
      return @contacts[id] if @contacts.key? id

      @contacts[id] = { id: }
    end

    def by_name_or_email(name, email)
      @contacts_lock.synchronize do
        @contacts.values.find { (!name.nil? && _1[:name] == name) || (!email.nil? && _1[:emails].include?(email)) }
      end
    end
  end

  def self.state
    @state ||= ContactsState.new
  end

  def self.reset_state!
    @state = nil
  end

  class ContactsServiceImpl < ContactsService
    def state = ContactsImpl.state

    def list_contacts = state.contacts.each_value { yield _1 }

    def get_contact(req)
      { contact: state.by_id(req.id) || not_found! }
    end

    def find_by_name_or_email(name, email)
      state.by_name_or_email(name, email)
    end or not_found!

    def divide(a, b) = [a / b, a % b]

    def upsert_contact(c)
      cont = state.get_or_initialize(c.id)
      cont[:name] = c.name
      cont[:surname] = c.surname
      cont[:company] = c.company
      cont[:emails] = c.emails
      cont[:telephones] = c.telephones
      cont[:social_handle] = c.social_handle
      cont[:additional_info] = c.additional_info
      cont.compact!
    end
  end
end
