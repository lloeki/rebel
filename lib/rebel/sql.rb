module Rebel::SQL
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

  def select(*fields, distinct: distinct, from: nil, where: nil, inner: nil, left: nil, right: nil, limit: nil, offset: nil)
    exec(Rebel::SQL.select(*fields,
                           distinct: distinct,
                           from: from,
                           where: where,
                           inner: inner,
                           left: left,
                           right: right,
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
      Raw.new("(#{self})")
    end

    def parens?
      wants_parens? ? parens : self
    end

    def as(n)
      Raw.new(self + " AS #{Rebel::SQL.name(n)}")
    end

    def as?(n)
      n ? as(n) : self
    end

    def on(*clause)
      Raw.new(self + " ON #{Rebel::SQL.and_clause(*clause)}")
    end

    def on?(*clause)
      clause.any? ? on(*clause) : self
    end

    def and(*clause)
      Raw.new("#{self.parens?} AND #{Rebel::SQL.and_clause(*clause)}")
    end

    def or(*clause)
      Raw.new("#{self} OR #{Rebel::SQL.and_clause(*clause)}").wants_parens!
    end

    def eq(n)
      case n
      when nil
        Raw.new("#{self} IS NULL")
      else
        Raw.new("#{self} = #{Rebel::SQL.name_or_value(n)}")
      end
    end
    alias == eq
    alias is eq

    def ne(n)
      case n
      when nil
        Raw.new("#{self} IS NOT NULL")
      else
        Raw.new("#{self} != #{Rebel::SQL.name_or_value(n)}")
      end
    end
    alias != ne

    def lt(n)
      Raw.new("#{self} < #{Rebel::SQL.name_or_value(n)}")
    end
    alias < lt

    def gt(n)
      Raw.new("#{self} > #{Rebel::SQL.name_or_value(n)}")
    end
    alias > gt

    def le(n)
      Raw.new("#{self} <= #{Rebel::SQL.name_or_value(n)}")
    end
    alias <= le

    def ge(n)
      Raw.new("#{self} >= #{Rebel::SQL.name_or_value(n)}")
    end
    alias >= ge

    def in(*v)
      Raw.new("#{self} IN (#{Rebel::SQL.values(*v)})")
    end

    def like(n)
      Raw.new("#{self} LIKE #{Rebel::SQL.value(n)}")
    end
  end

  @identifier_quote = '"'
  @string_quote = "'"
  @escaped_string_quote = "''"

  class << self
    def identifier_quote=(str)
      @identifier_quote = str
    end

    def string_quote=(str)
      @string_quote = str
    end

    def escaped_string_quote=(str)
      @escaped_string_quote = str
    end

    def raw(str)
      Raw.new(str)
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

    def select(*fields, distinct: nil, from: nil, where: nil, inner: nil, left: nil, right: nil, limit: nil, offset: nil)
      raw <<-SQL
      SELECT #{distinct ? "DISTINCT #{names(*distinct)}" : names(*fields)}
      #{from?(from)}
      #{inner?(inner)}
      #{left?(left)}
      #{right?(right)}
      #{where?(where)}
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
      str.tr(@string_quote, @escaped_string_quote)
    end

    def value(v)
      case v
      when Raw then v
      when String then raw "'#{escape_str(v)}'"
      when Integer then raw v.to_s
      when TrueClass, FalseClass then raw(v ? 'TRUE' : 'FALSE')
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

    def limit?(limit, offset)
      limit ? "LIMIT #{value(limit)}" << (offset ? " OFFSET #{offset}" : "") : nil
    end
  end
end
