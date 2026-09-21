# Migrations and snapshots

Owner: "this should be made with `mix ash.codegen` NOT `ash_postgres.generate_migrations`",
"we shouldn't be editing snapshots as they are created by ash automatically", "we
shouldn't be deleting snapshots as they are a history of the table", "we shouldn't be
renaming and updating migration files", "all migration code should be inside of a
migration file inside of `priv`", "remove this file, no need to test this migration".

- Generate with `mix ash.codegen --name <snake_case>` once, at the end of a change.
  Read the migration: it must only add what you changed. Check with `mix ash.codegen --check`.
  Never call `mix ash_postgres.generate_migrations` directly (the generated
  moduledoc still names that task; ash_postgres writes that text itself).
- Never hand-edit or delete a snapshot. If `mix ash.codegen` asks whether to drop a
  table whose resource is gone, answer `n` so the snapshot history is kept, and write
  the `drop table` into the migration by hand.
- Never rename or edit a migration that has been deployed. Re-timestamping is only for
  unreleased branches, and then the snapshot is renamed with it: a snapshot that sorts
  after a newer one for the same table makes `ash.codegen` regenerate columns that exist.
- Data migrations are SQL inside the migration file in `priv/repo/migrations`, never a
  module under `lib/`. Migrations are not unit-tested.
- One-off data fixes are run as standalone SQL, not committed as migrations.
