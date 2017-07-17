require 'minitest/autorun'
require 'helper'
require 'rebel'

class TestRaw < Minitest::Test
  def assert_str_equal(expected, actual)
    assert_equal(expected.to_s, actual.to_s)
  end

  def test_and
    assert_str_equal(Rebel::SQL.name(:foo).eq(1).and(Rebel::SQL.name(:bar).eq(2)), '"foo" = 1 AND "bar" = 2')
  end

  def test_or
    assert_str_equal(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2)), '"foo" = 1 OR "bar" = 2')
  end

  def test_and_or
    assert_str_equal(Rebel::SQL.name(:foo).eq(0).and(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2))), '"foo" = 0 AND ("foo" = 1 OR "bar" = 2)')
  end

  def test_or_and_or
    assert_str_equal(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2)).and(Rebel::SQL.name(:foo).eq(3).or(Rebel::SQL.name(:bar).eq(4))), '("foo" = 1 OR "bar" = 2) AND ("foo" = 3 OR "bar" = 4)')
  end

  def test_is
    assert_str_equal(Rebel::SQL.name(:foo).is(nil), '"foo" IS NULL')
    assert_str_equal(Rebel::SQL.name(:foo).is(42), '"foo" = 42')
    assert_str_equal(Rebel::SQL.name(:foo).is(Rebel::SQL.name(:bar)), '"foo" = "bar"')
  end

  def test_eq
    assert_str_equal(Rebel::SQL.name(:foo).eq(nil), '"foo" IS NULL')
    assert_str_equal(Rebel::SQL.name(:foo) == nil,  '"foo" IS NULL')
    assert_str_equal(Rebel::SQL.name(:foo).eq(Rebel::SQL.name(:bar)), '"foo" = "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) == Rebel::SQL.name(:bar),  '"foo" = "bar"')
  end

  def test_ne
    assert_str_equal(Rebel::SQL.name(:foo).ne(Rebel::SQL.name(:bar)), '"foo" != "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) != Rebel::SQL.name(:bar), '"foo" != "bar"')
    assert_str_equal(Rebel::SQL.name(:foo).ne(nil), '"foo" IS NOT NULL')
    assert_str_equal(Rebel::SQL.name(:foo) != nil, '"foo" IS NOT NULL')
  end

  def test_lt
    assert_str_equal(Rebel::SQL.name(:foo).lt(Rebel::SQL.name(:bar)), '"foo" < "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) <  Rebel::SQL.name(:bar),  '"foo" < "bar"')
  end

  def test_gt
    assert_str_equal(Rebel::SQL.name(:foo).gt(Rebel::SQL.name(:bar)), '"foo" > "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) >  Rebel::SQL.name(:bar),  '"foo" > "bar"')
  end

  def test_le
    assert_str_equal(Rebel::SQL.name(:foo).le(Rebel::SQL.name(:bar)), '"foo" <= "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) <= Rebel::SQL.name(:bar),  '"foo" <= "bar"')
  end

  def test_ge
    assert_str_equal(Rebel::SQL.name(:foo).ge(Rebel::SQL.name(:bar)), '"foo" >= "bar"')
    assert_str_equal(Rebel::SQL.name(:foo) >= Rebel::SQL.name(:bar),  '"foo" >= "bar"')
  end

  def test_in
    assert_str_equal(Rebel::SQL.name(:foo).in(1, 2, 3), '"foo" IN (1, 2, 3)')
  end

  def test_like
    assert_str_equal(Rebel::SQL.name(:foo).like('%bar%'), %("foo" LIKE '%bar%'))
  end

  def test_where
    assert_str_equal(Rebel::SQL.where?(foo: 1, bar: 2, baz: 3), 'WHERE "foo" = 1 AND "bar" = 2 AND "baz" = 3')
    assert_str_equal(Rebel::SQL.where?(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2)), Rebel::SQL.name(:baz).eq(3)), 'WHERE ("foo" = 1 OR "bar" = 2) AND "baz" = 3')
    assert_str_equal(Rebel::SQL.where?(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2))), 'WHERE ("foo" = 1 OR "bar" = 2)')
  end

  def test_join
    assert_str_equal(Rebel::SQL.join(:foo), 'JOIN "foo"')
  end

  def test_function
    assert_str_equal(Rebel::SQL.function('COALESCE', :foo, 0), 'COALESCE("foo", 0)')
  end

  def test_where_function
    assert_str_equal(Rebel::SQL.where?(Rebel::SQL.function('COALESCE', :foo, 0).eq 42), 'WHERE COALESCE("foo", 0) = 42')
  end

  def test_value
    assert_str_equal(Rebel::SQL.value(Rebel::SQL.raw("'FOO'")), "'FOO'")
    assert_str_equal(Rebel::SQL.value('FOO'), "'FOO'")
    assert_str_equal(Rebel::SQL.value(1), '1')
    assert_str_equal(Rebel::SQL.value(true), 'TRUE')
    assert_str_equal(Rebel::SQL.value(false), 'FALSE')
    assert_str_equal(Rebel::SQL.value(Date.new(2016, 12, 31)), "'2016-12-31'")
    assert_str_equal(Rebel::SQL.value(Time.utc(2016, 12, 31, 23, 59, 59)), "'2016-12-31T23:59:59Z'")
    assert_str_equal(Rebel::SQL.value(DateTime.new(2016, 12, 31, 23, 59, 59)), "'2016-12-31T23:59:59+00:00'")
    assert_str_equal(Rebel::SQL.value(nil), 'NULL')
  end

  def test_select
    assert_str_equal(Rebel::SQL.select(Rebel::SQL.raw('*'), from: Rebel::SQL.name(:foo)).gsub(/\s+/, ' ').strip, 'SELECT * FROM "foo"')
  end

  def test_nested_select
    assert_str_equal(Rebel::SQL.select(Rebel::SQL.raw('*'), from: Rebel::SQL.name(:foo), where: Rebel::SQL.name(:bar).in(Rebel::SQL.select(Rebel::SQL.name(:bar), from: Rebel::SQL.name(:foo)))).gsub(/\s+/, ' ').strip, 'SELECT * FROM "foo" WHERE "bar" IN ( SELECT "bar" FROM "foo" )')
  end
end
