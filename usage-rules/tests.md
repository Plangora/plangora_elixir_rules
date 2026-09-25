# Tests

## Data comes from the factory

Owner: "we should ALWAYS be using `generate/1`", "pipe `contact/1` into `generate/1`",
"remove all `Plangora.Factory` in the test files as they are already imported".

```elixir
# BAD
Plangora.Factory.user(admin: true) |> generate()
{:ok, user} = User |> Ash.Changeset.for_create(:create, %{...}) |> Ash.create()
user = create_admin!(org)

# GOOD
admin = generate(user(admin: true)) |> load_actor()
contact = contact(email: "pat@example.com") |> generate()
```

Setup is inline in each test so the data it depends on is visible; a private helper is
only for a multi-step setup repeated many times in one file. Use
`System.unique_integer()` for identity fields in async tests. Add a factory function
when one is missing instead of building the record by hand. Going through the real
action is right only when the action itself is what the test proves.

## Every module is async

"why `async: false`?", "can this be `async: true`?", "can we replace this with Mox
instead? if so, then we can change this test to be `async: true`". Global config and
named processes are replaced with Mox or per-test injection; a module that truly
cannot be async says why in a comment.

## Assertions

- Counts with `Ash.count!/2` ("we can just run a count is probably more clear: make sure it's `0`").
- Fetch with `Ash.get!/2`; clear with `Ash.bulk_destroy!`.
- Verify the database effect, not only the response ("let's also verify that it's created in the database").
- Both `assert html =~ "text"` and `refute html =~ "text"` on rendered HTML are fine;
  use `has_element?/2` or `element/2` when a DOM id is the clearer target.
- Shared `load_actor/1` goes in `setup`.
- Delete pointless tests ("pointless test", "remove this file, useless").

## Actor in tests

"can a user not see their own contact? you used `authorize?: false`". Tests pass the
actor; `authorize?: false` is only for setup that deliberately bypasses policies, and
says so.

## Suite health

- The connection pool must exceed ExUnit's `max_cases`, or async tests time out.
- Rebuild a test database that has been used with committed rows (`MIX_ENV=test mix ecto.reset`
  with the partition set); `mix ecto.drop` without `MIX_ENV=test` drops the dev database.
