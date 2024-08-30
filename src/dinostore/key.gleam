import dinostore/ulid
import gleam/dynamic
import gleam/result

pub type KeyPart {
  StringPart(value: String)
  /// Number parts are represented as floats since JavaScript does not differentiate
  /// between integers and floats.
  NumberPart(value: Float)
  BoolPart(value: Bool)
}

/// A key is simply a list of `KeyPart`s.
pub type Key =
  List(KeyPart)

/// Helper function to create a `StringPart`.
pub fn s(s: String) -> KeyPart {
  StringPart(s)
}

/// Helper function to create a `NumberPart`.
pub fn n(n: Float) -> KeyPart {
  NumberPart(n)
}

/// Helper function to create a `BoolPart`.
pub fn b(b: Bool) -> KeyPart {
  BoolPart(b)
}

/// Create a ULID key part. To create a new ULID without a key, use the
/// `new` function in the `dinostore/ulid` module.
///
/// [Official Documentation](https://jsr.io/@std/ulid)
///
pub fn ulid() -> KeyPart {
  StringPart(ulid.new())
}

pub type JsKey

/// Turn a Gleam `Key` into a normal JavaScript key (of the TS type
/// `(string | number | boolean)[]`) by unwrapping the value of each `KeyPart`.
/// Use `decode` to convert the key back to a `Key`.
///
/// Both this function and `decode` are helpful for creating
/// [secondary indexes](https://docs.deno.com/deploy/kv/manual/#improve-querying-with-secondary-indexes)
/// where a primary key is stored as a secondary index's value.
///
/// ```
/// io.debug(unwrap([s("foo"), n(1.0), b(True)]))
/// // => #("foo", 1.0, True)
/// // Gleam tuples are represented as JavaScript arrays under the hood
/// ```
///
@external(javascript, "../dinostore.ffi.ts", "toJsKey")
pub fn unwrap(key: Key) -> JsKey

/// Decode a normal JavaScript key (e.g. one created with `unwrap` and stored in
/// the database) into a Gleam `Key`.
///
/// Both this function and `unwrap` are helpful for creating
/// [secondary indexes](https://docs.deno.com/deploy/kv/manual/#improve-querying-with-secondary-indexes)
/// where a primary key is stored as a secondary index's value.
///
pub fn decode(x: dynamic.Dynamic) {
  dynamic.list(
    of: dynamic.any(of: [
      fn(x) { result.map(dynamic.string(x), StringPart) },
      fn(x) { result.map(dynamic.float(x), NumberPart) },
      fn(x) { result.map(dynamic.bool(x), BoolPart) },
    ]),
  )(x)
}
