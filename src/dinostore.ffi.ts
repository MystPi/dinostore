import * as kv from './dinostore/kv.mjs';
import { Key, StringPart, NumberPart, BoolPart } from './dinostore/key.mjs';
import * as gleam from './gleam.mjs';
import * as option from '../gleam_stdlib/gleam/option.mjs';
export { ulid } from 'jsr:@std/ulid@^1';

export function open(path?: string) {
  return Deno.openKv(path);
}

export function close(conn: Deno.Kv) {
  conn.close();
}

export function toJsKey(key: Key) {
  return key.toArray().map((part) => part.value);
}

function toGleamKey(key: Deno.KvKey) {
  return gleam.toList(
    key.map((part) => {
      if (typeof part === 'string') {
        return new StringPart(part);
      } else if (typeof part === 'number') {
        return new NumberPart(part);
      } else if (typeof part === 'boolean') {
        return new BoolPart(part);
      }

      throw new Error(`Invalid key part`);
    })
  );
}

export async function get(conn: Deno.Kv, k: Key) {
  const { key, value, versionstamp } = await conn.get(toJsKey(k));

  if (value === null && versionstamp === null) {
    return new gleam.Error(toGleamKey(key));
  }

  return new gleam.Ok(new kv.Entry(toGleamKey(key), value, versionstamp));
}

export async function set(
  conn: Deno.Kv,
  k: Key,
  value: unknown,
  expiration: option.Option$<number>
) {
  if (value instanceof gleam.List) {
    value = value.toArray();
  }

  const expireIn =
    expiration instanceof option.Some ? expiration[0] : undefined;

  const result = await conn.set(toJsKey(k), value, { expireIn });
  return result.versionstamp;
}

export async function del(conn: Deno.Kv, k: Key) {
  await conn.delete(toJsKey(k));
}

export async function list(
  conn: Deno.Kv,
  prefix: Key,
  reverse: boolean,
  has_limit: option.Option$<number>,
  has_cursor: option.Option$<string>
) {
  const limit = has_limit instanceof option.Some ? has_limit[0] : undefined;
  const cursor = has_cursor instanceof option.Some ? has_cursor[0] : undefined;
  const entries = conn.list(
    { prefix: toJsKey(prefix) },
    { limit, reverse, cursor }
  );
  const result = [];

  for await (const { key, value, versionstamp } of entries) {
    result.push(new kv.Entry(toGleamKey(key), value, versionstamp));
  }

  return gleam.toList(result);
}

export function newOperation(conn: Deno.Kv) {
  return conn.atomic();
}

export function atomicCheck(
  op: Deno.AtomicOperation,
  key: Key,
  versionstamp: option.Option$<string>
) {
  return op.check({
    key: toJsKey(key),
    versionstamp: versionstamp instanceof option.Some ? versionstamp[0] : null,
  });
}

export function atomicCheckEntry(op: Deno.AtomicOperation, entry: kv.Entry) {
  return op.check({
    key: toJsKey(entry.key),
    versionstamp: entry.versionstamp,
  });
}

export async function atomicCommit(op: Deno.AtomicOperation) {
  const result = await op.commit();

  if (result.ok) {
    return new gleam.Ok(result.versionstamp);
  } else {
    return new gleam.Error();
  }
}

export function atomicDelete(op: Deno.AtomicOperation, key: Key) {
  return op.delete(toJsKey(key));
}

export function atomicSet(
  op: Deno.AtomicOperation,
  key: Key,
  value: unknown,
  expiration: option.Option$<number>
) {
  if (value instanceof gleam.List) {
    value = value.toArray();
  }

  const expireIn =
    expiration instanceof option.Some ? expiration[0] : undefined;

  return op.set(toJsKey(key), value, { expireIn });
}
