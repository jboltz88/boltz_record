require 'boltz_record/utility'
require 'boltz_record/schema'
require 'boltz_record/persistence'
require 'boltz_record/selection'
require 'boltz_record/connection'
require 'boltz_record/collection'

module BoltzRecord
  class Base
    include Persistence
    extend Selection
    extend Schema
    extend Connection

    def initialize(options={})
      options = BoltzRecord::Utility.convert_keys(options)

      self.class.columns.each do |col|
        self.class.send(:attr_accessor, col)
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end

# Entry.where(...)
# Entry.save <--- won't work

# entry = Entry.where(...).first
# Change it here
# entry.save
