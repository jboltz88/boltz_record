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

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  def destroy
    self.class.destroy(self.id)
  end

  def method_missing(method_name, *arguments, &block)
    if method_name.to_s =~ /update_(.*)/
      update_attribute($1, *arguments[0])
    else
      super
    end
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

    def update(ids, updates)
      if updates.class == Array
        updates.each_with_index do |update, index|
          update(ids[index], update)
        end
      else updates.class == Hash
        updates = BoltzRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{BoltzRecord::Utility.sql_strings(value)}" }

        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        sql = <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL

        connection.execute(sql)
        true
      end
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL
      true
    end

    def destroy_all(*conditions_hash)
      params = nil
      if !conditions_hash.empty?
        if conditions_hash.length > 1
          conditions = conditions_hash.shift
          params = conditions_hash
        else
          conditions_hash = conditions_hash.first
          if conditions_hash.class == Hash
            conditions_hash = BoltzRecord::Utility.convert_keys(conditions_hash)
            conditions = conditions_hash.map { |key, value| "#{key}=#{BoltzRecord:Utility.sql_strings(value)}"}.join(" AND ")
          elsif conditions_hash.class == String
            conditions = conditions_hash
          end
        end

        sql = <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions}
        SQL
      else
        sql = <<-SQL
          DELETE FROM #{table}
        SQL
      end
      puts sql
      puts params
      connection.execute(sql, params)
      true
    end
  end
end
