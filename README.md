# activerecord-metal

Because sometimes you need just SQL only.

## Installation

    gem install activerecord-metal

## Usage - Querying

The initial impulse to build activerecord-metal is that I needed to run custom SQL
queries and wanted properly typed results - something that ActiveRecord gives you
only for columns that are defined in the table layout, (and "count", probably), 
but not for custom calculated values.

So there is support for queries.

    # use the current ActiveRecord::Base connection
    metal = ActiveRecord::Metal.new

    # ask for single results
    metal.ask "SELECT 2+4"        # => 6
    metal.ask "SELECT '2+4=6'"    # => '2+4=6'

    # properly deduce types
    metal.ask "SELECT '1999-01-01 00:00:00'::timestamp"     # => returns a Time object

    # iterate over results
    metal.exec("SELECT id, name FROM users") do |id, name| 
      # do something with id and name
      # ...
    end

    # also metal.exec returns all rows in an array, which also
    # contains some type information.
    results = metal.exec("SELECT id, name FROM users")      # => ary
    results.types                                           # => [ Numerical, String ]
    results.columns                                         # => [ "id", "name" ]

    # This information is contained in each of the rows also
    row = results.first
    row.types                                               # => [ Numerical, String ]
    row.columns                                             # => [ "id", "name" ]

    # use positional parameters: note: Rails' '?' placeholders don't work here,
    # only what is the database's default; and Postgresql uses $1, $2, ...
    metal.exec("SELECT id, name FROM users WHERE name=$1", "me")

## Usage - prepared queries

ActiveRecord::Metal uses prepared queries whenever a query uses parameters. They
are managed automatically behind your back. You can also explicitely prepare
queries:

    prepared_query = metal.prepare(sql)

and use the prepared_query instead of the sql string.

    metal.ask prepared_query, arg1, arg2, ...

To unprepare the query use 

    metal.unprepare(prepared_query)
    metal.unprepare(sql)

**Note:** ActiveRecord::Metal currently does not automatically unprepare
queries.

## Usage - Mass import

    # Mass imports for array records
    #
    records = [
      [1, "first user"],
      [2, "second user"],
      [3, "third user"]
    ]
    
    # 
    metal.import "users", records                                     # fill from left
    metal.import "users", records, :columns => [ "id", "name" ]       # preferred

    # Mass imports for hash records
    #
    records = [
      {id:1, name:"first user", email:"first-user@inter.net"},
      {id:2, name:"second user"},
      {id:3, name:"third user"}
    ]
    
    # 
    metal.import "users", records

### How fast is the mass import?

The metal's importer is fast, ceause it just does importing data - that 
means it does not fetch ids, it does not validate records, does not call
callbacks.

This results in an impressive speedup compared to ActiveRecord::Base:

    1.9.2 ~/projects/gem/activerecord-metal[master] > bundle exec script/console 
    Loaded /Users/eno/.irbrc
    irb(main):001:0> ActiveRecord::Metal::Postgresql.etest 
    Loaded suite ActiveRecord::Metal::Postgresql::Etest
    Started
    ....
    INFO -- : 7.8 msecs INSERT 100 hashes into alloys
    INFO -- : 6.8 msecs INSERT 100 arrays into alloys
    INFO -- : 63.6 msecs Import 100 hashes via ActiveRecord::Base
    INFO -- : 670.3 msecs INSERT 10000 hashes into alloys
    INFO -- : 676.9 msecs INSERT 10000 arrays into alloys
    INFO -- : 6520.9 msecs Import 10000 hashes via ActiveRecord::Base

A 10 times speed up sounds massive (and will probably become even faster once
the `COPY FROM STDIN` importer is completed)), but on the other hand 
ActiveRecord::Base imports a single record in less than 700 microseconds, 
which is probably fast enough for most cases.

## Why not ActiveRecord::Base?

ActiveRecord::Base is limited in several ways. It does not

- defer data types from what is in the database - unless it is a column in one of your models.
- sometimes builds very slow queries
- use prepared statements (AFAIK)
- activerecord < 4 does not make use of hstore types

## Why not ActiveRecord::Metal?

ActiveRecord::Metal depends heavily on features of specific databases and 
adapters. It currently works only on Postgres. Your SQL must be adapted 
to the database server. There is no validation (except what you are 
implementing in SQL). And of course: the code base is not exactly mature ;)

And documentation is still missing. Code coverage is good, though:

    All Files (97.22% covered at 88.78 hits/line)
    6 files in total. 288 relevant lines. 280 lines covered and 8 lines missed

## Hacking ActiveRecord::Metal

The following gives you a IRB console

    bundle exec script/console

## License

The activerecord-metal gem is distributed under the terms of the Modified BSD License, see LICENSE.BSD for details.

