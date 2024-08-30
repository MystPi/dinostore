import dinostore/atomic
import dinostore/key
import dinostore/kv
import gleam/bool
import gleam/dynamic
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None}
import gleam/result

pub fn main() {
  use conn <- promise.await(kv.open_with_path(":memory:"))

  use _ <- promise.await(add_user(conn, "bob", 100.0))
  use _ <- promise.await(add_user(conn, "alice", 100.0))

  io.println("Original funds:")
  use users <- promise.await(list_users(conn))
  list.each(users, io.debug)

  use _ <- promise.await(transfer_funds(conn, "bob", "alice", 10.0))

  io.println("Funds after transfer:")
  use users <- promise.await(list_users(conn))
  list.each(users, io.debug)

  promise.resolve(Nil)
}

fn add_user(
  conn: kv.Connection,
  username: String,
  balance: Float,
) -> Promise(Result(String, Nil)) {
  let key = [key.s("account"), key.s(username)]

  atomic.new(conn)
  // Make sure the user doesn't already exist
  |> atomic.check(key, None)
  // Add the user
  |> atomic.set(key, balance, expiration: None)
  |> atomic.commit()
}

fn list_users(conn: kv.Connection) -> Promise(List(#(String, Float))) {
  use entries <- promise.await(kv.list(
    conn,
    prefix: [key.s("account")],
    reverse: False,
    limit: None,
    cursor: None,
  ))

  list.map(entries, fn(entry) {
    let assert Ok(balance) = dynamic.float(entry.value)
    let assert Ok(key.StringPart(name)) = list.last(entry.key)
    #(name, balance)
  })
  |> promise.resolve
}

type TransferError {
  InvalidAmount
  AccountNotFound(key.Key)
  InsufficientFunds
}

fn transfer_funds(
  conn: kv.Connection,
  sender: String,
  receiver: String,
  amount: Float,
) -> Promise(Result(String, TransferError)) {
  use <- bool.guard(
    when: amount <. 0.0,
    return: promise.resolve(Error(InvalidAmount)),
  )

  let sender_key = [key.s("account"), key.s(sender)]
  let receiver_key = [key.s("account"), key.s(receiver)]

  use sender_entry <- promise.try_await(get_account(conn, sender_key))
  use receiver_entry <- promise.try_await(get_account(conn, receiver_key))

  let assert Ok(sender_balance) = dynamic.float(sender_entry.value)
  let assert Ok(receiver_balance) = dynamic.float(receiver_entry.value)

  use <- bool.guard(
    when: sender_balance <. amount,
    return: promise.resolve(Error(InsufficientFunds)),
  )

  let new_sender_balance = sender_balance -. amount
  let new_receiver_balance = receiver_balance +. amount

  use res <- promise.await(
    atomic.new(conn)
    |> atomic.check_entry(sender_entry)
    |> atomic.check_entry(receiver_entry)
    |> atomic.set(sender_key, new_sender_balance, expiration: None)
    |> atomic.set(receiver_key, new_receiver_balance, expiration: None)
    |> atomic.commit(),
  )

  case res {
    Ok(vs) -> promise.resolve(Ok(vs))
    // if the checks fail, the function will be re-run until the checks succeed
    Error(Nil) -> transfer_funds(conn, sender, receiver, amount)
  }
}

fn get_account(
  conn: kv.Connection,
  key: key.Key,
) -> Promise(Result(kv.Entry, TransferError)) {
  use entry <- promise.await(kv.get(conn, key))
  result.map_error(entry, fn(e) {
    let kv.NotFound(key) = e
    AccountNotFound(key)
  })
  |> promise.resolve
}
