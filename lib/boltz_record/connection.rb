require 'sqlite3'

module Connection
  def connection
    @connection ||= SQLite3::Database.new(BoltzRecord.database_filename)
  end
end
