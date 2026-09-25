# Ash resources

## Archival and paper trail on every resource

Owner, in review: "we should have `ash_archival` and `ash_paper_trail`" (said on every
resource that lacked them, join tables included).

```elixir
use Ash.Resource,
  domain: MyApp.Domain,
  data_layer: AshPostgres.DataLayer,
  extensions: [AshPaperTrail.Resource, AshArchival.Resource],
  authorizers: [Ash.Policy.Authorizer]

paper_trail do
  change_tracking_mode :changes_only
  store_action_name? true
  store_action_inputs? true
  ignore_attributes [:inserted_at, :updated_at]        # plus every secret or sensitive attribute
  mixin MyApp.VersionIndexesMixin                      # composite primary keys need their own mixin
  belongs_to_actor :actor, MyApp.Accounts.User, domain: MyApp.Accounts
  belongs_to_actor :system_actor, MyApp.Accounts.SystemUser, domain: MyApp.Accounts
end

archive do
  exclude_read_actions [:get]                          # reads that must still find archived rows
  exclude_destroy_actions [:hard_destroy]
  base_filter? false
end
```

The domain needs `extensions: [AshPaperTrail.Domain]` and `paper_trail do include_versions? true end`.

Secrets never reach the version table: put tokens, hashes and government IDs in
`ignore_attributes` **and** mark the attribute `sensitive?: true`.

Adding archival changes behaviour. Every time, check:

- identities that should be unique among live rows only:
  `identity :name, [...], where: expr(is_nil(archived_at))` plus
  `identity_wheres_to_sql name: "archived_at IS NULL"` in the `postgres` block
  ("we'll need to take in account about the `archived_at`");
- upserts on such an identity must revive: `change set_attribute(:archived_at, nil)` and
  `:archived_at` in `upsert_fields` when the conflict target is a database unique index;
- internal lookups by id and "who did this" loads go through an excluded read action;
- the test factory pins `archived_at: StreamData.constant(nil)`.

## Relationships: argument + manage_relationship

Owner: "this should be using manage_relationship", "these should be using argument with
`manage_relationship`", "if we are changing relationships, we need to use argument with
`manage_relationship`", "remove `attribute_writable?: true` and replace with: `public?: true`",
"remove this line and add to relationships the connection to user".

```elixir
# BAD
create :create do
  accept [:project_id, :title]
end

belongs_to :project, MyApp.Projects.Project, attribute_writable?: true
attribute :project_id, :uuid, allow_nil?: false

# GOOD
create :create do
  accept [:title]
  argument :project_id, :uuid, allow_nil?: false
  change manage_relationship(:project_id, :project, type: :append_and_remove)
end

belongs_to :project, MyApp.Projects.Project, allow_nil?: false, public?: true
```

The params map is unchanged (`%{project_id: ...}` still works), so callers and forms
need no change. Exceptions, each commented at the site: an attribute that is part of an
upsert identity's conflict target may stay accepted; "the actor is the author" is
`change relate_actor(:author)`; a nested create through the parent's `manage_relationship`
gets its foreign key from the parent and needs no argument for it.

## Everything public

"make public", "let's add `public? true`": attributes, relationships, calculations and
aggregates are `public? true`. The exceptions are secrets (`hashed_password`, tokens).

## Actions

"let's add this to `action.defaults` and setup `actions.default_accept`", "you can
combine them into line 23 and just set the arguments: `create: [:name, :kind, :description]`".

```elixir
actions do
  defaults [:read, :destroy, create: [:name, :description], update: [:name, :description]]

  update :publish do
    accept []                       # state transitions accept nothing
    change set_attribute(:published_at, &DateTime.utc_now/0)
  end
end
```

Find-or-create is a `create` with `upsert? true` and an `upsert_identity`, not a read
followed by a branch ("i think the create action with upsert can handle all of this").

## Enums

"this should be `Ash.Type.Enum`", "let's use `Ash.Type.Enum` with a `gettext` label":

```elixir
defmodule MyApp.CRM.LoginStatus do
  @moduledoc "Whether a contact has a usable login."
  use Gettext, backend: MyAppWeb.Gettext

  use Ash.Type.Enum,
    values: [
      no_login: [label: gettext("No login")],
      invited: [label: gettext("Invited")],
      active: [label: gettext("Active")]
    ]

  def label(nil), do: nil

  def label(value) do
    with label when is_binary(label) <- super(value) do
      Gettext.gettext(MyAppWeb.Gettext, label)
    end
  end
end
```

An attribute constrained with `one_of` becomes an enum type. Validation and policy
`message:`s are wrapped in `gettext/1`.

## Loading and querying

- Load related data with the parent: `Ash.get!(Card, id, load: [comments: [:author]], actor: actor)`,
  not a follow-up query ("When we load the card why not load this at the same time?").
- `Ash.get/3` when you already have the id.
- Sort in the query (`Ash.Query.sort`), never in memory ("sort within the query, not within memory").
- Derived numbers are calculations ("we can make a single calculation which adds these together");
  counts are aggregates; "the default X" is a filtered `has_one`.
- Business logic that derives values from a resource (totals, costs, margins, budget
  usage, "which rate applied on this date") lives on the resource as calculations,
  aggregates and relationships -- not in a service module or a LiveView helper
  ("we should prefer to use calculations, aggregations, and these kinds of ash constructs").
  They are cached once loaded, reachable from the API (AshGraphql) without rebuilding
  the logic, and unit-testable with `Ash.load!/3`. Prefer expression calculations so they
  run in SQL and compose into other expressions and aggregates; hide sensitive ones with
  field policies instead of a hand-written permission check.
- Search is a `read :search` action with a `:ci_string` argument and `contains/2`, not
  a hand-built `ilike` ("you can use `contains` and also setup a search action that can do this with an argument").

## Database shape

- Foreign-key indexes come from `references do reference :user, on_delete: :delete, index?: true end`,
  not `custom_indexes` on the FK column.
- `validate one_of(...)` on an attribute lives in `validations do ... where: changing(:x) end`.
