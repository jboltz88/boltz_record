require 'sqlite3'

module Selection
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM table
        WHERE id IN (#{ids.join(",")})
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    if id < 0
      raise ArgumentError.new("ID must be a positive integer")
    else
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    end
  end

  def find_by(attribute, value)
    valid = false
    for att in columns
      if att == attribute.to_s
        valid = true
      end
    end
    if valid == false
      raise ArgumentError.new("Invalid field: #{attribute}")
    else
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{attribute} = #{BoltzRecord::Utility.sql_strings(value)};
      SQL

      init_object_from_row(row)
    end
  end

  def find_each(hash)
    if hash
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY id
        LIMIT #{hash["batch_size"]} OFFSET #{hash["start"]};
      SQL
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY id;
      SQL
    end

    row_array = rows_to_array(rows)
    row_array.each do |row|
      yield(row)
    end
  end

  def find_in_batches(hash)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      LIMIT #{hash["limit"]} OFFSET #{hash["offset"]}
    SQL

    rows_to_array(rows)
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def method_missing(method_name, *arguments, &block)
    if method_name.to_s =~ /find_by_(.*)/
      find_by($1, *arguments[0])
    else
      super
    end
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BoltzRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key}=#{BoltzRecord::Utility.sql_strings(value)}"}.join(" AND ")
      end
    end
    # where("email = ? AND phone = ?", useremail, phone)

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL
    puts sql
    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BoltzRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        expression_hash = BoltzRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key} ON #{key}.#{table}_id = #{table}.id
                     INNER JOIN #{BoltzRecord::Utility.sql_strings(value)} ON #{BoltzRecord::Utility.sql_strings(value)}.#{key}_id = #{key}.id"}.join(" INNER JOIN ")

        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{expression};
        SQL
      end
    end

    rows_to_array(rows)
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BoltzRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
