# dinostore

Bindings to the [`Deno.Kv`](https://docs.deno.com/deploy/kv/manual/) database.

[![Package Version](https://img.shields.io/hexpm/v/dinostore)](https://hex.pm/packages/dinostore)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/dinostore/)

## Setup

```sh
gleam add dinostore

# You will also need gleam_javascript if not already installed
gleam add gleam_javascript
```

Your `gleam.toml` config will need the JavaScript runtime set to `deno`.

```toml
target = "javascript"

[javascript]
runtime = "deno"
```

Make sure that your `deno.json` also contains the following configuration:

```json
{
  "unstable": ["kv"]
}
```

## A note on serialization

Deno KV uses the [structured clone algorithm](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm) to store values. This means that Gleam values such as custom types will be converted to JavaScript objects before being stored in the database. For example, consider the following custom type:

```gleam
type Book {
  Book(title: String, author: String)
}
```

A constructed value such as `Book(title: "foo", author: "bar")` will be stored in the database as a JavaScript object when cloned:

```json
{ "title": "foo", "author": "bar" }
```

`Dynamic` decoders should be carefully written with this in mind. It may be helpful to inspect the value retrieved from the database before decoding it to see how it has changed.

For convenience, `List`s are automatically converted to JavaScript arrays before being stored in the database.

## Example

In the following program, several `let assert`s are used when decoding `Dynamic` data. When creating wrapper functions for the database, you can be certain that the retrieved data is correctly structured, provided that these wrapper functions are consistently used instead of directly accessing the raw database. Ultimately, it's up to you to decide how to handle the case where parsing data fails.

```gleam
import dinostore/atomic
import dinostore/key
import dinostore/kv
import gleam/dynamic
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/option.{None}

type Cat =
  #(String, Int)

fn decode_cat(x: dynamic.Dynamic) {
  dynamic.tuple2(dynamic.string, dynamic.int)(x)
}

fn add_cat(conn: kv.Connection, cat: Cat) -> Promise(Result(String, Nil)) {
  let primary_key = [key.s("cats"), key.ulid()]
  let by_name = [key.s("cats_by_name"), key.s(cat.0)]

  atomic.new(conn)
  // Check that the key does not already exist
  |> atomic.check(by_name, None)
  // Create the primary and secondary keys
  |> atomic.set(primary_key, cat, expiration: None)
  |> atomic.set(by_name, key.unwrap(primary_key), expiration: None)
  // Attempt to commit the mutations
  |> atomic.commit
}

fn get_cat_by_name(
  conn: kv.Connection,
  name: String,
) -> Promise(Result(Cat, kv.GetError)) {
  let secondary_key = [key.s("cats_by_name"), key.s(name)]

  use primary_key_entry <- promise.try_await(kv.get(conn, secondary_key))
  let assert Ok(primary_key) = key.decode(primary_key_entry.value)

  use entry <- promise.try_await(kv.get(conn, primary_key))
  let assert Ok(cat) = decode_cat(entry.value)

  promise.resolve(Ok(cat))
}

pub fn main() {
  use conn <- promise.await(kv.open_with_path(":memory:"))

  // Add two cats to the database. Note that here we are ignoring add_cat's
  // results; in a more sophisticated program you would want to handle error
  // cases appropriately.
  use _ <- promise.await(add_cat(conn, #("Fluffy", 2)))
  use _ <- promise.await(add_cat(conn, #("Oreo", 10)))

  // Retrieve a cat by its name
  use cat <- promise.await(get_cat_by_name(conn, "Oreo"))

  let _ = io.debug(cat)
  //=> #("Oreo", 10)

  promise.resolve(Nil)
}
```

A more involved example can be found in [./test](https://github.com/MystPi/dinostore/tree/main/test).

## Documentation

Further documentation can be found at <https://hexdocs.pm/dinostore>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the test project
```
