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

  def test_where
    assert_str_equal(Rebel::SQL.where?(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2)), Rebel::SQL.name(:baz).eq(3)), 'WHERE ("foo" = 1 OR "bar" = 2) AND "baz" = 3')
    assert_str_equal(Rebel::SQL.where?(Rebel::SQL.name(:foo).eq(1).or(Rebel::SQL.name(:bar).eq(2))), 'WHERE "foo" = 1 OR "bar" = 2')
  end
end
