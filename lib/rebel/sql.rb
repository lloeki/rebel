module Rebel::SQLQ
  attr_reader :conn

  def exec(query)
    conn.exec(query)
  end

  def create_table(table_name, desc)
    exec(Rebel::SQL.create_table(table_name, desc))
  end

  def drop_table(table_name)
    exec(Rebel::SQL.drop_table(table_name))
  end

  def select(*fields, distinct: nil, from: nil, where: nil, inner: nil, left: nil, right: nil, group: nil, order: nil, limit: nil, offset: nil)
    exec(Rebel::SQL.select(*fields,
                           distinct: distinct,
                           from: from,
                           where: where,
                           inner: inner,
                           left: left,
                           right: right,
                           group: group,
                           order: order,
                           limit: limit,
                           offset: offset))
  end

  def insert_into(table_name, *rows)
    exec(Rebel::SQL.insert_into(table_name, *rows))
  end

  def update(table_name, set: nil, where: nil, inner: nil, left: nil, right: nil)
    exec(Rebel::SQL.update(table_name, set: set, where: where, inner: inner, left: left, right: right))
  end

  def delete_from(table_name, where: nil, inner: nil, left: nil, right: nil)
    exec(Rebel::SQL.delete_from(table_name, where: where, inner: inner, left: left, right: right))
  end

  def truncate(table_name)
    exec(Rebel::SQL.truncate(table_name))
  end

  def count(*n)
    Rebel::SQL.count(*n)
  end

  def join(table, on: nil)
    Rebel::SQL.join(table, on: on)
  end

  def outer_join(table, on: nil)
    Rebel::SQL.outer_join(table, on: on)
  end
end

module Rebel
  class Raw < String
    def wants_parens!
      @wants_parens = true
      self
    end

    def wants_parens?
      @wants_parens = false unless instance_variable_defined?(:@wants_parens)
      @wants_parens
    end

    def parens
      sql.raw("(#{self})")
    end

    def parens?
      wants_parens? ? parens : self
    end

    def as(n)
      sql.raw(self + " AS #{sql.name(n)}")
    end

    def as?(n)
      n ? as(n) : self
    end

    def on(*clause)
      sql.raw(self + " ON #{sql.and_clause(*clause)}")
    end

    def on?(*clause)
      clause.any? ? on(*clause) : self
    end

    def having(*clause)
      sql.raw(self + " HAVING #{sql.and_clause(*clause)}")
    end

    def asc
      sql.raw(self + " ASC")
    end

    def desc
      sql.raw(self + " DESC")
    end

    def and(*clause)
      sql.raw("#{self.parens?} AND #{sql.and_clause(*clause)}")
    end
    alias & and

    def or(*clause)
      sql.raw("#{self} OR #{sql.and_clause(*clause)}").wants_parens!
    end
    alias | or

    def eq(n)
      case n
      when nil
        sql.raw("#{self} IS NULL")
      else
        sql.raw("#{self} = #{sql.name_or_value(n)}")
      end
    end
    alias == eq
    alias is eq

    def ne(n)
      case n
      when nil
        sql.raw("#{self} IS NOT NULL")
      else
        sql.raw("#{self} != #{sql.name_or_value(n)}")
      end
    end
    alias != ne
    alias is_not ne

    def lt(n)
      sql.raw("#{self} < #{sql.name_or_value(n)}")
    end
    alias < lt

    def gt(n)
      sql.raw("#{self} > #{sql.name_or_value(n)}")
    end
    alias > gt

    def le(n)
      sql.raw("#{self} <= #{sql.name_or_value(n)}")
    end
    alias <= le

    def ge(n)
      sql.raw("#{self} >= #{sql.name_or_value(n)}")
    end
    alias >= ge

    def in(*v)
      sql.raw("#{self} IN (#{sql.values(*v)})")
    end

    def not_in(*v)
      sql.raw("#{self} NOT IN (#{sql.values(*v)})")
    end

    def like(n)
      sql.raw("#{self} LIKE #{sql.value(n)}")
    end

    def not_like(n)
      sql.raw("#{self} NOT LIKE #{sql.value(n)}")
    end

    private

    def sql
      @sql ||= Rebel::SQLQ
    end
  end

  module SQLB
    def raw(str)
      Raw.new(str).tap { |r| r.instance_variable_set(:@sql, self) }
    end

    def create_table(table_name, desc)
      raw <<-SQL
      CREATE TABLE #{name(table_name)} (
        #{list(desc.map { |k, v| "#{name(k)} #{v}" })}
      )
      SQL
    end

    def drop_table(table_name)
      raw <<-SQL
      DROP TABLE #{name(table_name)}
      SQL
    end

    def select(*fields, distinct: nil, from: nil, where: nil, inner: nil, left: nil, right: nil, group: nil, order: nil, limit: nil, offset: nil)
      raw <<-SQL
      SELECT #{distinct ? "DISTINCT #{names(*distinct)}" : names(*fields)}
      #{from?(from)}
      #{inner?(inner)}
      #{left?(left)}
      #{right?(right)}
      #{where?(where)}
      #{group?(group)}
      #{order?(order)}
      #{limit?(limit, offset)}
      SQL
    end

    def insert_into(table_name, *rows)
      raw <<-SQL
      INSERT INTO #{name(table_name)} (#{names(*rows.first.keys)})
      VALUES #{list(rows.map { |r| "(#{values(*r.values)})" })}
      SQL
    end

    def update(table_name, set: nil, where: nil, inner: nil, left: nil, right: nil)
      raise ArgumentError if set.nil?

      raw <<-SQL
      UPDATE #{name(table_name)}
      SET #{assign_clause(set)}
      #{inner?(inner)}
      #{left?(left)}
      #{right?(right)}
      #{where?(where)}
      SQL
    end

    def delete_from(table_name, where: nil, inner: nil, left: nil, right: nil)
      raw <<-SQL
      DELETE FROM #{name(table_name)}
      #{inner?(inner)}
      #{left?(left)}
      #{right?(right)}
      #{where?(where)}
      SQL
    end

    def truncate(table_name)
      raw <<-SQL
      TRUNCATE #{name(table_name)}
      SQL
    end

    ## Functions

    def function(name, *args)
      raw("#{name}(#{names_or_values(*args)})")
    end
    alias fn function

    def by(*n)
      raw("BY #{names(*n)}")
    end

    def count(*n)
      raw("COUNT(#{names(*n)})")
    end

    def join(table, on: nil)
      raw("JOIN #{name(table)}").on?(on)
    end

    def outer_join(table, on: nil)
      raw("OUTER JOIN #{name(table)}").on?(on)
    end

    def inner_join(table, on: nil)
      raw(inner? join(table, on: on))
    end

    def left_outer_join(table, on: nil)
      raw(left? outer_join(table, on: on))
    end

    def right_outer_join(table, on: nil)
      raw(right? outer_join(table, on: on))
    end

    ## Support

    def name(name)
      return name if name.is_a?(Raw)
      return raw('*') if name == '*'

      raw(name.to_s.split('.').map { |e| "#{@identifier_quote}#{e}#{@identifier_quote}" }.join('.'))
    end

    def names(*names)
      list(names.map { |k| name(k) })
    end

    def list(*items)
      items.join(', ')
    end

    def escape_str(str)
      str.gsub(@string_quote, @escaped_string_quote)
    end

    def value(v)
      case v
      when Raw then v
      when String then raw "#{@string_quote}#{escape_str(v)}#{@string_quote}"
      when Integer then raw v.to_s
      when TrueClass, FalseClass then raw(v ? @true_literal : @false_literal)
      when Date, Time, DateTime then value(v.iso8601)
      when nil then raw 'NULL'
      else raise NotImplementedError, "#{v.class}: #{v.inspect}"
      end
    end

    def values(*values)
      list(values.map { |v| value(v) })
    end

    def name_or_value(item)
      item.is_a?(Symbol) ? name(item) : value(item)
    end

    def names_or_values(*items)
      list(items.map { |v| name_or_value(v) })
    end

    def equal(l, r)
      "#{name_or_value(l)} = #{name_or_value(r)}"
    end

    def assign_clause(clause)
      list(clause.map { |k, v| equal(k, v) })
    end

    def clause_term(left, right)
      case right
      when Array
        name(left).in(*right)
      else
        name(left).eq(name_or_value(right))
      end
    end

    def and_clause(*clause)
      clause.map do |e|
        case e
        when Hash then and_clause(*e.to_a)
        when Array then clause_term(e[0], e[1])
        when Raw then e.parens?
        when String then e
        else raise NotImplementedError, e.class
        end
      end.join(' AND ')
    end

    def from?(from)
      from ? "FROM #{name(from)}" : nil
    end

    def where?(*clause)
      clause.any? ? "WHERE #{and_clause(*clause)}" : nil
    end

    def inner?(join)
      join ? "INNER #{join}" : nil
    end

    def left?(join)
      join ? "LEFT #{join}" : nil
    end

    def right?(join)
      join ? "RIGHT #{join}" : nil
    end

    def group?(group)
      group ? "GROUP #{name(group)}" : nil
    end

    def order?(order)
      order ? "ORDER #{name(order)}" : nil
    end

    def limit?(limit, offset)
      limit ? "LIMIT #{value(limit)}" << (offset ? " OFFSET #{offset}" : "") : nil
    end
  end
end

module Rebel
  def self.SQL(options = {}, &block)
    sql = const_defined?(:SQL) && options.empty? ? SQL : Module.new do
      @identifier_quote = options[:identifier_quote] || '"'
      @string_quote = options[:string_quote] || "'"
      @escaped_string_quote = options[:escaped_string_quote] || "''"
      @true_literal = options[:true_literal] || 'TRUE'
      @false_literal = options[:false_literal] || 'FALSE'

      extend Rebel::SQLB
      include Rebel::SQLQ
    end

    return sql.instance_eval(&block) unless block.nil?

    sql
  end

  SQL = SQL()
end
