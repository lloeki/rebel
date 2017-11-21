require 'minitest/autorun'
require 'helper'
require 'rebel'

class TestRaw < Minitest::Test
  def assert_sql(expected, &actual)
    assert_equal(expected.to_s, Rebel::SQL.instance_eval(&actual).to_s)
  end

  def test_and
    assert_sql('"foo" = 1 AND "bar" = 2') { name(:foo).eq(1).and(name(:bar).eq(2)) }
    assert_sql('"foo" = 1 AND "bar" = 2') { name(:foo).eq(1) & name(:bar).eq(2) }
    assert_sql('"foo" = 1 AND "bar" = 2') { (name(:foo) == 1) & (name(:bar) == 2) }
  end

  def test_or
    assert_sql('"foo" = 1 OR "bar" = 2') { name(:foo).eq(1).or(name(:bar).eq(2)) }
    assert_sql('"foo" = 1 OR "bar" = 2') { name(:foo).eq(1) | name(:bar).eq(2) }
    assert_sql('"foo" = 1 OR "bar" = 2') { (name(:foo) == 1) | (name(:bar) == 2) }
  end

  def test_and_or
    assert_sql('"foo" = 0 AND ("foo" = 1 OR "bar" = 2)') { name(:foo).eq(0).and(name(:foo).eq(1).or(name(:bar).eq(2))) }
    assert_sql('"foo" = 0 AND ("foo" = 1 OR "bar" = 2)') { name(:foo).eq(0) & (name(:foo).eq(1) | name(:bar).eq(2)) }
  end

  def test_or_and_or
    assert_sql('("foo" = 1 OR "bar" = 2) AND ("foo" = 3 OR "bar" = 4)') { name(:foo).eq(1).or(name(:bar).eq(2)).and(name(:foo).eq(3).or(name(:bar).eq(4))) }
    assert_sql('("foo" = 1 OR "bar" = 2) AND ("foo" = 3 OR "bar" = 4)') { (name(:foo).eq(1) | name(:bar).eq(2)) & (name(:foo).eq(3) | name(:bar).eq(4)) }
  end

  def test_and_or_and
    assert_sql('"foo" = 1 AND "bar" = 2 OR "foo" = 3 AND "bar" = 4') { name(:foo).eq(1).and(name(:bar).eq(2)).or(name(:foo).eq(3).and(name(:bar).eq(4))) }
    assert_sql('"foo" = 1 AND "bar" = 2 OR "foo" = 3 AND "bar" = 4') { name(:foo).eq(1) & name(:bar).eq(2) | name(:foo).eq(3) & name(:bar).eq(4) }
  end

  def test_is
    assert_sql('"foo" IS NULL') { name(:foo).is(nil) }
    assert_sql('"foo" = 42') { name(:foo).is(42) }
    assert_sql('"foo" = "bar"') { name(:foo).is(name(:bar)) }
  end

  def test_is_not
    assert_sql('"foo" IS NOT NULL') { name(:foo).is_not(nil) }
    assert_sql('"foo" != 42') { name(:foo).is_not(42) }
    assert_sql('"foo" != "bar"') { name(:foo).is_not(name(:bar)) }
  end

  def test_eq
    assert_sql('"foo" IS NULL') { name(:foo).eq(nil) }
    assert_sql('"foo" IS NULL') { name(:foo) == nil }
    assert_sql('"foo" = "bar"') { name(:foo).eq(name(:bar)) }
    assert_sql('"foo" = "bar"') { name(:foo) == name(:bar) }
  end

  def test_ne
    assert_sql('"foo" != "bar"') { name(:foo).ne(name(:bar)) }
    assert_sql('"foo" != "bar"') { name(:foo) != name(:bar) }
    assert_sql('"foo" IS NOT NULL') { name(:foo).ne(nil) }
    assert_sql('"foo" IS NOT NULL') { name(:foo) != nil }
  end

  def test_lt
    assert_sql('"foo" < "bar"') { name(:foo).lt(name(:bar)) }
    assert_sql('"foo" < "bar"') { name(:foo) <  name(:bar) }
  end

  def test_gt
    assert_sql('"foo" > "bar"') { name(:foo).gt(name(:bar)) }
    assert_sql('"foo" > "bar"') { name(:foo) >  name(:bar) }
  end

  def test_le
    assert_sql('"foo" <= "bar"') { name(:foo).le(name(:bar)) }
    assert_sql('"foo" <= "bar"') { name(:foo) <= name(:bar) }
  end

  def test_ge
    assert_sql('"foo" >= "bar"') { name(:foo).ge(name(:bar)) }
    assert_sql('"foo" >= "bar"') { name(:foo) >= name(:bar) }
  end

  def test_in
    assert_sql('"foo" IN (1, 2, 3)') { name(:foo).in(1, 2, 3) }
  end

  def test_not_in
    assert_sql('"foo" NOT IN (1, 2, 3)') { name(:foo).not_in(1, 2, 3) }
  end

  def test_like
    assert_sql(%("foo" LIKE '%bar%')) { name(:foo).like('%bar%') }
  end

  def test_not_like
    assert_sql(%("foo" NOT LIKE '%bar%')) { name(:foo).not_like('%bar%') }
  end

  def test_where
    assert_sql('WHERE "foo" = 1 AND "bar" = 2 AND "baz" = 3') { where?(foo: 1, bar: 2, baz: 3) }
    assert_sql('WHERE ("foo" = 1 OR "bar" = 2) AND "baz" = 3') { where?(name(:foo).eq(1).or(name(:bar).eq(2)), name(:baz).eq(3)) }
    assert_sql('WHERE ("foo" = 1 OR "bar" = 2)') { where?(name(:foo).eq(1).or(name(:bar).eq(2))) }
  end

  def test_join
    assert_sql('JOIN "foo"') { join(:foo) }
  end

  def test_function
    assert_sql('COALESCE("foo", 0)') { function('COALESCE', :foo, 0) }
  end

  def test_where_function
    assert_sql('WHERE COALESCE("foo", 0) = 42') { where?(function('COALESCE', :foo, 0).eq 42) }
  end

  def test_value
    assert_sql("'FOO'") { value(raw("'FOO'")) }
    assert_sql("'FOO'") { value('FOO') }
    assert_sql('1') { value(1) }
    assert_sql('TRUE') { value(true) }
    assert_sql('FALSE') { value(false) }
    assert_sql("'2016-12-31'") { value(Date.new(2016, 12, 31)) }
    assert_sql("'2016-12-31T23:59:59Z'") { value(Time.utc(2016, 12, 31, 23, 59, 59)) }
    assert_sql("'2016-12-31T23:59:59+00:00'") { value(DateTime.new(2016, 12, 31, 23, 59, 59)) }
    assert_sql('NULL') { value(nil) }
  end

  def test_select
    assert_sql('SELECT * FROM "foo"') { select(raw('*'), from: name(:foo)).gsub(/\s+/, ' ').strip }
  end

  def test_select_without_from
    assert_sql('SELECT 1') { select(raw('1')).strip }
  end

  def test_select_distinct
    assert_sql('SELECT DISTINCT "bar" FROM "foo"') { select(distinct: :bar, from: :foo).gsub(/\s+/, ' ').strip }
  end

  def test_select_distinct_multiple
    assert_sql('SELECT DISTINCT "bar", "baz" FROM "foo"') { select(distinct: [:bar, :baz], from: :foo).gsub(/\s+/, ' ').strip }
  end

  def test_select_group_by
    assert_sql('SELECT "bar" FROM "foo" GROUP BY "baz"') { select(:bar, from: :foo, group: by(:baz)).gsub(/\s+/, ' ').strip }
  end

  def test_select_group_by_having
    assert_sql('SELECT "bar" FROM "foo" GROUP BY "baz" HAVING COUNT("qux") > 5') { select(:bar, from: :foo, group: by(:baz).having(count(:qux).gt(5))).gsub(/\s+/, ' ').strip }
  end

  def test_select_order_by
    assert_sql('SELECT "bar" FROM "foo" ORDER BY "baz"') { select(:bar, from: :foo, order: by(:baz)).gsub(/\s+/, ' ').strip }
  end

  def test_select_order_by_asc
    assert_sql('SELECT "bar" FROM "foo" ORDER BY "baz" ASC') { select(:bar, from: :foo, order: by(:baz).asc).gsub(/\s+/, ' ').strip }
  end

  def test_select_order_by_desc
    assert_sql('SELECT "bar" FROM "foo" ORDER BY "baz" DESC') { select(:bar, from: :foo, order: by(:baz).desc).gsub(/\s+/, ' ').strip }
  end

  def test_select_multiple_order_by
    assert_sql('SELECT "bar" FROM "foo" ORDER BY "baz", "qux"') { select(:bar, from: :foo, order: by(:baz, :qux)).gsub(/\s+/, ' ').strip }
  end

  def test_select_multiple_order_by_opposing
    assert_sql('SELECT "bar" FROM "foo" ORDER BY "baz" ASC, "qux" DESC') { select(:bar, from: :foo, order: by(name(:baz).asc, name(:qux).desc)).gsub(/\s+/, ' ').strip }
  end

  def test_select_limit
    assert_sql('SELECT "bar" FROM "foo" LIMIT 10') { select(:bar, from: :foo, limit: 10).gsub(/\s+/, ' ').strip }
  end

  def test_select_offset
    assert_sql('SELECT "bar" FROM "foo" LIMIT 10 OFFSET 20') { select(:bar, from: :foo, limit: 10, offset: 20).gsub(/\s+/, ' ').strip }
  end

  def test_nested_select
    assert_sql('SELECT * FROM "foo" WHERE "bar" IN ( SELECT "bar" FROM "foo" )') { select(raw('*'), from: name(:foo), where: name(:bar).in(select(name(:bar), from: name(:foo)))).gsub(/\s+/, ' ').strip }
  end
end
