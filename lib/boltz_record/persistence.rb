require 'sqlite3'
require 'boltz_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(BoltzRecord::Utility.instance_variables_to_hash(self)).id
      BoltzRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BoltzRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET    #{fields}
      WHERE  id = #{self.id};
    SQL

    true
  end

  module ClassMethods
    def create(attrs)
      attrs = BoltzRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BoltzRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end
  end
end
