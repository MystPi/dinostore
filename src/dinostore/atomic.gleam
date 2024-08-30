//// This module provides bindings to the [`Deno.AtomicOperation`](https://docs.deno.com/api/deno/~/Deno.AtomicOperation)
//// API. Read more about it [here](https://docs.deno.com/deploy/kv/manual/transactions/).
////

import dinostore/key.{type Key}
import dinostore/kv.{type Connection}
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}

pub type AtomicOperation

/// Create a new [`AtomicOperation`](#AtomicOperation).
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation)
///
@external(javascript, "../dinostore.ffi.ts", "newOperation")
pub fn new(conn: Connection) -> AtomicOperation

/// Commit the operation to the database. A return of `Ok(versionstamp)` means
/// that the operation was successful and all checks passed; a return of
/// `Error(Nil)` means that at least one check failed and no mutations were
/// made.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation#method_commit_0)
///
@external(javascript, "../dinostore.ffi.ts", "atomicCommit")
pub fn commit(op: AtomicOperation) -> Promise(Result(String, Nil))

/// Add a key-versionstamp check to the operation. If the versionstamp is `None`,
/// the check will make sure the key-value pair does not already exist in the
/// database.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation#method_check_0)
///
@external(javascript, "../dinostore.ffi.ts", "atomicCheck")
pub fn check(
  op: AtomicOperation,
  key key: Key,
  versionstamp versionstamp: Option(String),
) -> AtomicOperation

/// Add a check based on an `Entry`'s key and versionstamp to the operation.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation#method_check_0)
///
@external(javascript, "../dinostore.ffi.ts", "atomicCheckEntry")
pub fn check_entry(op: AtomicOperation, entry: kv.Entry) -> AtomicOperation

/// Add to the operation a mutation that deletes the specified key if all checks
/// pass during the commit.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation#method_delete_0)
///
@external(javascript, "../dinostore.ffi.ts", "atomicDelete")
pub fn delete(op: AtomicOperation, key: Key) -> AtomicOperation

/// Add to the operation a mutation that sets the value of the specified key to
/// the specified value if all checks pass during the commit.
///
/// An expiration (time-to-live, or TTL) can be specified in milliseconds. The
/// key will be deleted from the database at earliest after the specified number
/// of milliseconds have elapsed. Once the duration has passed, the key may still
/// be visible or some additional time. If an expiration is not specified, the
/// key will not expire.
///
/// [Official Documentation](https://docs.deno.com/api/deno/~/Deno.AtomicOperation#method_set_0)
///
@external(javascript, "../dinostore.ffi.ts", "atomicSet")
pub fn set(
  op: AtomicOperation,
  key key: Key,
  value value: a,
  expiration expiration: Option(Int),
) -> AtomicOperation
