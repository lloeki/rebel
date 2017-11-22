# Rebel - Ruby-flavored SQL

SQL-flavored Ruby.

```
You've been fighting yet another abstraction...
Aren't you fed up with object-relation magic?
But wait, here comes a humongous migration.
Is ActiveRecord making you sick?
To hell with that monstrous Arel expression!
Tell the truth, you were just wishing
That it was as simple as a here-string.
But could it keep some Ruby notation
Instead of silly interpolations?
Stop the menace, time for a revolution!

Rebel!

No magic
No bullshit
No layers
No wrappers
No smarty-pants
No sexy
No nonsense
No AST
No lazy loading
No crazy mapping

What you write is what you get: readable and obvious
What you write is what you meant: tasty and delicious

Wait, it doesn't execute!?
Just use your fave client gem, isn't that cute?
```

## Motivation

There are many a time where you end up knowing exactly what SQL query you want,
yet have to wrap your head around for the ORM to produce it, which is when the
point of such a layer is entirely defeated. Concatenating and interpolating
only goes so far.

As ActiveRecord grows, a significant decision has been taken in the Rails team
to turn Arel into a library purely internal to ActiveRecord: the whole of it is
basically considered internal and private, and only ActiveRecord's public
interface should be used. Unfortunately, some highly dynamic, complex queries
simply cannot be built using ActiveRecord, and concatenating strings to build
SQL fragments and clauses simply does not cut it.

## Philosophy

- It must be readable as being SQL
- Yet it must be as much Ruby syntax and types as possible
- It must be able to produce fragments for others to use
- And somehow be composable enough
- It must not rely on metaprogramming magic
- Nor need monkeypatching core types

## Design

There are two goals to this library:

- query building
- query execution

Query building is about assembling a string containing a partial or complete
query that you will later pass on to be executed by an executor.

Query execution is about writing a query that will be executed on the spot.

There are also non-goals to this library:

- be any sort of ORM
- or any sort of abstraction layer
- or any sort of query optimiser

## Usage

`Rebel::SQL` is a module that contains building and execution features, and
output ANSI-style SQL.

`Rebel::SQL()` is a function that produces a customised module enabling support
for alternative dialects, and when passed a block, allows you to write things
more literally.

Ruby types are best-effort mapped to SQL entities in a simple, regular way:

- Symbols map to quoted SQL names such as tables, columns, aliases.
- Strings map to strings. Always. (Quote style can be configured).
- Integers and floats map to, well, integers and floats.
- Date, Time and DateTime map to their ISO 8601 string representation
- Booleans map to their respective ANSI literals (unless overriden by
  configuration).
- `nil` maps to `NULL` and is expected to have the same "unknown" semantic

Variable arguments are generally used. Hashes, depending on context, map to:

- `=` equality or `IN` operators joined by `AND`
- `=` assignment operator joined by commas

## Examples

### Query building

```ruby
require 'rebel'

# Here's a typical query
Rebel::SQL.select :id, from: :customers, where: { :first_name => 'John', :last_name => 'Doe' }
=> SELECT "id" FROM "customers" WHERE "first_name" = 'John' AND "last_name" = 'Doe'

# More args give more columns
Rebel::SQL.select :first_name, :last_name, from: :customers, where: { :id => [1, 2, 3] }
=> SELECT "first_name", "last_name" FROM "customers" WHERE "id" IN (1, 2, 3)

# * is special-cased for names
Rebel::SQL.select :*, from: :customers, where: { :id => [1, 2, 3] }
=> SELECT * FROM "customers" WHERE "id" IN (1, 2, 3)

# You can emit fragments to produce clauses
puts Rebel::SQL.and_clause :id => [1, 2, 3], :country => 'GB'
=> "id" IN (1, 2, 3) AND "country" = 'GB'
Rebel::SQL.where? :id => [1, 2, 3], :country => 'GB'
=> WHERE "id" IN (1, 2, 3) AND "country" = 'GB'

# Here the question mark means where? swallows nil arguments: maybe it's a Maybe monad
Rebel::SQL.where?(nil)
=> nil

# Let's emit join clauses
Rebel::SQL.join(:contracts, on: :customer_id => :id)
#=> JOIN "contracts" ON "customer_id" = "id"
Rebel::SQL.join(:contracts).on(:customer_id => :id)
#=> JOIN "contracts" ON "customer_id" = "id"

# :contracts might have an :id too, so we can disambiguate those columns
Rebel::SQL.join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"

# Other types of join are obviously available
Rebel::SQL.inner_join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> INNER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
Rebel::SQL.outer_join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> OUTER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
Rebel::SQL.left_outer_join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> LEFT OUTER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
Rebel::SQL.right_outer_join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> RIGHT OUTER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"

# The type of join can be split off. Again, note the question mark.
Rebel::SQL.inner? Rebel::SQL.join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> INNER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
Rebel::SQL.left? Rebel::SQL.outer_join(:contracts).on(:'contracts.customer_id' => :'customers.id')
#=> LEFT OUTER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"

# And in a full query
Rebel::SQL.select :'customers.id', :'contracts.id',
                  from: :customers,
                  where: { :first_name => 'John', :last_name => 'Doe' },
                  inner: Rebel::SQL.join(:contracts).on(:'contracts.customer_id' => :'customers.id'),
                  order: Rebel::SQL.by(:'customer.age').asc
#=> SELECT "customers"."id", "contracts"."id"
#   FROM "customers"
#   INNER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
#   WHERE "first_name" = 'John' AND "last_name" = 'Doe'
#   ORDER BY "customer"."age" ASC

# All those Rebel::SQL can get unwieldy, so let's reduce the noise
Rebel::SQL() do
  select :'customers.id', :'contracts.id',
         from: :customers,
         where: { :first_name => 'John', :last_name => 'Doe' },
         inner: join(:contracts).on(:'contracts.customer_id' => :'customers.id'),
         order: by(:'customer.age').asc
end
#=> SELECT "customers"."id", "contracts"."id"
#   FROM "customers"
#   INNER JOIN "contracts" ON "contracts"."customer_id" = "customers"."id"
#   WHERE "first_name" = 'John' AND "last_name" = 'Doe'
#   ORDER BY "customer"."age" ASC

# Now, that function can be used to make things different
Rebel::SQL.name(:foo)
#=> "foo"
Rebel::SQL(identifier_quote: '`').name(:foo)
#=> `foo`
Rebel::SQL.value(true)
#=> TRUE
Rebel::SQL(true_literal: '1').value(true)
#=> 1
Rebel::SQL(true_literal: '1') { select value(true) }
#=> SELECT 1

# While we're at it, let's call arbitrary functions
Rebel::SQL() { select function('NOW') }
#=> SELECT NOW()
Rebel::SQL() { select function('LENGTH', "a string") }
#=> SELECT LENGTH('a string')
Rebel::SQL() { select function('COUNT', :id), from: :customers, where: { :age => 42 } }
#=> SELECT COUNT("id") FROM "customers" WHERE "age" = 42
Rebel::SQL() { select count(:id), from: :customers, where: { :age => 42 } }
#=> SELECT COUNT("id") FROM "customers" WHERE "age" = 42

# And throw in some aliases
Rebel::SQL() { select function('LENGTH', "a string").as(:length) }
#=> SELECT LENGTH('a string') AS "length"
Rebel::SQL() { select name(:id).as(:customer_id), from: :customers }
#=> SELECT "id" AS "customer_id" FROM "customers"
Rebel::SQL() { select count(:id).as(:count), from: :customers, where: { :age => 42 } }
#=> SELECT COUNT("id") FROM "customers" WHERE "age" = 42

# While we're counting things, let's group results
Rebel::SQL() { select count(:id).as(:count), :country, from: :customers, group: by(:country).having(count(:customer_id) => 5) }
#=> SELECT COUNT("id") AS "count", "country" FROM "customers" GROUP BY "country" HAVING COUNT("customer_id") = 5
```

### Query execution

If you provide Rebel::SQL an environment within which a query executor is
available, queries can be executed directly.

```ruby
class CreateTableCustomers
  include Rebel::SQL

  # provide a connection that responds to exec(query)
  def conn
    @conn ||= PG.connect( dbname: 'sales' )
  end

  # remember that SQL() returns a module!
  include Rebel::SQL(true_literal: '1', false_literal: '0')

  # alternatively, redefine the provided exec (which calls conn.exec)
  def exec(query)
    @db ||= SQLite3::Database.new "test.db"
    @db.execute(query)
  end

  def up
    create_table :customers, {
        id:         'SERIAL',
        name:       'VARCHAR(255)',
        address:    'VARCHAR(255)',
        city:       'VARCHAR(255)',
        zip:        'VARCHAR(255)',
        country:    'VARCHAR(255)',
    }

    insert_into :customers,
                { name: 'Lewis Caroll', address: '1, Alice St.', city: 'Oxford', zip: '1865', country: 'Wonderland' },
                { name: 'Neal Stephenson', address: '2, Hiro Blvd.', city: 'Los Angeles', zip: '1992', country: 'Metaverse' }

    results = select :name, :country, from: :customers

    update :customers, set: { city: 'FooTown' }, where: { zip: 1234 }

    delete_from :customers, where: { zip: 1234 }

    truncate :customers
  end

  def down
    drop_table :customers
  end
end
```

## FAQ

### X is missing/database specific, how do I write it?

You can use `Rebel::SQL.raw("whatever")` and drop it in.

### Why the weird syntax like `inner: join` instead of `inner_join`?

This allows for a more uniform interface as well as not monkeypatching core types.

### Can I write nonsensical SQL with this?

Yes. Just as you can write nonsensical SQL in SQL.

### Your query builder is not using an AST.

That's not a question. You're welcome to implement one that does though, and if
it leverages the visitor pattern, allocates a trajillion objects along the way
and manages to produce invalid SQL in some corner cases, well congratulations
for reimplementing Arel.

## License

MIT

## Caveat

This is totes not secure in any fscking way you could ever imagine, and this is
valid for every single definition of *secure* you could ever think of (and even
the ones you don't).
