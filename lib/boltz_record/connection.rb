require 'sqlite3'
require 'pg'

module Connection
  def connection
    if BoltzRecord.database_type == :sqlite3
      @connection ||= SQLite3::Database.new(BoltzRecord.database_filename)
    elsif BoltzRecord.database_type == :pg
      @connection ||= PG::Connection.open(:dbname => BoltzRecord.database_filename)
    end
  end
end
