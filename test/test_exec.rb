require 'minitest/autorun'
require 'helper'
require 'rebel'

class TestExec < Minitest::Test
  include Rebel::SQL

  def setup
    @conn = memdb
  end

  def test_create_table
    assert_raises(SQLite3::SQLException) { conn.execute('SELECT * FROM foo') }
    create_table :foo, id: 'INT', col: 'VARCHAR(255)'
    assert_equal(conn.execute('SELECT * FROM foo'), [])
  end

  def test_drop_table
    create_table :foo, id: 'INT', col: 'VARCHAR(255)'
    assert_equal(conn.execute('SELECT * FROM foo'), [])
    drop_table :foo
    assert_raises(SQLite3::SQLException) { conn.execute('SELECT * FROM foo') }
  end

  def test_insert_into
    create_table :foo, id: 'INT', col: 'VARCHAR(255)'
    insert_into :foo, id: 1, col: 'whatevs'
    assert_equal(conn.execute('SELECT * FROM foo'), [[1, 'whatevs']])
  end

  def test_insert_into_with_many_values
    create_table :foo, id: 'INT', col: 'VARCHAR(255)'
    insert_into :foo,
                { id: 1, col: 'more' },
                { id: 2, col: 'rows' },
                { id: 3, col: 'for the win' }
    assert_equal(conn.execute('SELECT * FROM foo'), [
      [1, 'more'],
      [2, 'rows'],
      [3, 'for the win'],
    ])
  end

  def test_select
    create_table :foo, id: 'INT', col: 'VARCHAR(255)'
    insert_into :foo, id: 1, col: 'whatevs'
    assert_equal(select(:*, from: :foo), [[1, 'whatevs']])
  end
end
