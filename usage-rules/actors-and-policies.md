# Actors and policies

## Every Ash call takes an actor

Owner: "each call to Ash functions that can take an actor should give an actor",
"why can't we use the actor?", "can a user not see their own contact? you used
`authorize?: false`", "why not use 1 query for both and we should be able to use the actor".

- LiveViews, components, controllers, code interfaces, MCP and GraphQL resolvers
  always pass `actor: socket.assigns.current_user` (or the conn's actor).
- When a screen needs rows the actor's row policy hides, add a policy or a dedicated
  read action with its own policy on the resource. Do not bypass authorization in the view.
- Background workers, notifiers and importers that act *for* someone pass that person
  as the actor (the user who connected the integration, the notification's recipient).
  Load them through a read action excluded from the archive filter when an archived
  user must still be found.
- `authorize?: false` is allowed only:
  - inside a resource's own changes and hooks, within an already-authorized action's
    transaction, for internal row churn (repositioning siblings, archiving children);
  - in a worker with genuinely no human actor, together with
    `bypass AshOban.Checks.AshObanInteraction do authorize_if always() end` on the
    resource when AshOban triggers it;
  - for the token lookup itself on a token-authenticated endpoint (an ICS feed, a
    webhook) — after which the request runs as the token's user.

  Every remaining `authorize?: false` carries a one-line comment saying why there is no actor.

## Permissions are policies

Owner: "let's implement this as a policy, instead. it makes it easier to manage as it's
not a validation problem, it's more of a permission issue", "we can wrap these
validations for this into policies", "basically admin should have a `bypass` and
otherwise CRUD should be done by the schedule's user".

```elixir
policies do
  bypass actor_attribute_equals(:admin, true) do
    authorize_if always()
  end

  bypass AshOban.Checks.AshObanInteraction do
    authorize_if always()
  end

  policy action_type(:read) do
    authorize_if expr(user_id == ^actor(:id))
  end

  # A rule that must bind admins too goes inside the policy, after the forbid.
  policy action_type(:destroy) do
    forbid_if expr(is_default == true)
    authorize_if actor_attribute_equals(:admin, true)
  end
end
```

An unscoped `bypass` overrides every later `forbid_if`; put admin-binding rules inside
the policy as above. `no_filter_static_forbidden_reads? false` needs `access_type :strict`.

## The web layer asks, it does not decide

"do we need this function? we cannot just directly use `Ash.can?/2`?", "Let's not check
if we can edit here". Gate UI with `Ash.can?({record, :action}, actor)` or
`Ash.can?({Resource, :action, %{arg: value}}, actor)`; do not pre-check in event
handlers what the action itself enforces, and do not keep helper functions that
re-implement a policy.
