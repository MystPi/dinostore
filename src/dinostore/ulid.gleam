//// Read more about ULIDs in the
//// [official Deno docs](https://docs.deno.com/deploy/kv/manual/key_space/#universally-unique-lexicographically-sortable-identifiers-(ulids)).
////

/// Generate a new ULID.
///
/// [Official Documentation](https://jsr.io/@std/ulid)
///
@external(javascript, "../dinostore.ffi.ts", "ulid")
pub fn new() -> String
