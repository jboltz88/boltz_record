require 'sqlite3'
require 'pg'
require 'active_support/inflector'

module Associations
  def has_many(association)
    define_method(association) do
      rows = self.class.connection.execute <<-SQL
        SELECT * FROM #{association.to_s.singularize}
        WHERE #{self.class.table}_id = #{self.id}
      SQL

      class_name = association.to_s.classify.constantize
      collection = BoltzRecord::Collection.new

      rows.each do |row|
        collection << class_name.new(Hash[class_name.columns.zip(row)])
      end
      collection
    end
  end

  def has_one(association)
    define_method(association) do
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association.to_s.singularize}
        WHERE #{self.class.table}_id = #{self.id}
      SQL

      class_name = association_name.to_s.classify.constantize

      if row
        class_name.new(Hash[class_name.columns.zip(row)])
      end
    end
  end

  def belongs_to(association)
    define_method(association) do
      association_name = association.to_s
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association_name}
        WHERE id = #{self.send(association_name + "_id")}
      SQL

      class_name = association_name.classify.constantize

      if row
        class_name.new(Hash[class_name.columns.zip(row)])
      end
    end
  end
end
