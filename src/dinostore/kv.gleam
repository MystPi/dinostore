//// Bindings to the [`Deno.Kv`](https://docs.deno.com/deploy/kv/manual/) database.
////

import dinostore/key.{type Key}
import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}

pub type Connection

/// An entry in the database. Since the value is `Dynamic`, it needs to be parsed
/// before it can be used in any useful way.
///
pub type Entry {
  Entry(key: Key, value: Dynamic, versionstamp: String)
}

/// Errors that can be returned from functions that retrieve entries from the
/// database.
///
pub type GetError {
  /// The key was not found in the database.
  NotFound(Key)
}

/// Open a new `Deno.Kv` connection to the default database location. This may be
/// local or remote, depending on where the program is run.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.openKv)
///
/// ```
/// use conn <- promise.await(open())
/// ```
///
@external(javascript, "../dinostore.ffi.ts", "open")
pub fn open() -> Promise(Connection)

/// Open a new `Deno.Kv` connection to the database at the given path. The path
/// `:memory:` can be used to connect to an in-memory database.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.openKv)
///
/// ```
/// use conn <- promise.await(open_with_path(":memory:"))
/// ```
///
@external(javascript, "../dinostore.ffi.ts", "open")
pub fn open_with_path(path: String) -> Promise(Connection)

/// Use this function to close a database connection manually.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.Kv#method_close_0)
///
@external(javascript, "../dinostore.ffi.ts", "close")
pub fn close(conn: Connection) -> Nil

/// Retrieve the value and versionstamp for the given key from the database,
/// returning an [`Entry`](#Entry) or [`GetError`](#GetError).
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.Kv#method_get_0)
///
@external(javascript, "../dinostore.ffi.ts", "get")
pub fn get(conn: Connection, key key: Key) -> Promise(Result(Entry, GetError))

/// Set the value for the given key in the database. If a value already exists
/// for the key, it will be overwritten. This operation, by definition, cannot
/// fail, so it returns the new versionstamp of the key.
///
/// An expiration (time-to-live, or TTL) can be specified in milliseconds. The
/// key will be deleted from the database at earliest after the specified number
/// of milliseconds have elapsed. Once the duration has passed, the key may still
/// be visible or some additional time. If an expiration is not specified, the
/// key will not expire.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.Kv#method_set_0)
///
@external(javascript, "../dinostore.ffi.ts", "set")
pub fn set(
  conn: Connection,
  key key: Key,
  value value: a,
  expiration expiration: Option(Int),
) -> Promise(String)

/// Delete the value for the given key from the database. If no value exists for
/// the key, this operation is a no-op (hence the `Nil` return).
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.Kv#method_delete_0)
///
@external(javascript, "../dinostore.ffi.ts", "del")
pub fn delete(conn: Connection, key key: Key) -> Promise(Nil)

/// Retrieve all entries with the given key prefix from the database. The entries
/// will be returned in reverse lexicographical order if `reverse` is `True`.
/// `cursor` can be used to start the retrieval from a specific point.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.Kv#method_list_0)
///
/// [Read more about key ordering](https://docs.deno.com/deploy/kv/manual/key_space/#key-part-ordering)
///
/// ```
/// use entries <- promise.await(list(["books"], reverse: False, limit: None))
/// use entry <- list.each(entries)
/// io.debug(entry)
/// ```
///
///
@external(javascript, "../dinostore.ffi.ts", "list")
pub fn list(
  conn: Connection,
  prefix prefix: Key,
  reverse reverse: Bool,
  limit limit: Option(Int),
  cursor cursor: Option(String),
) -> Promise(List(Entry))
