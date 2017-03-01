require 'pry'
require 'sqlite3'

def memdb
  SQLite3::Database.new(':memory:').tap do |db|
    db.class.instance_eval { alias_method :exec, :execute }
  end
end
