# Cinder collections

Owner: "please continue to convert the tables to using `cinder`".

Every paginated list over an Ash resource is a `Cinder.collection`. Do not build it by
hand from `<.table>` + `stream/3` + `AshPhoenix.LiveView.params_to_page_opts/2` + a
pagination component + `AshPhoenix.FilterForm`. `<.table>` is only for a short list
already in memory (an invoice's lines, a detail modal).

## The LiveView

```elixir
use PlangoraWeb, :live_view
use Cinder.UrlSync

@impl true
def handle_params(params, uri, socket) do
  {:noreply,
   params
   |> Cinder.UrlSync.handle_params(uri, socket)
   |> assign(
     banks_query:
       Bank
       |> Ash.Query.for_read(:list_search, search_args(params), actor: socket.assigns.current_user)
       |> Ash.Query.sort(name: :asc)
       |> Ash.Query.load([:client]),
     params: params,
     patch: ~p"/admin/banks?#{Map.drop(params, ["id"])}"
   )
   |> apply_action(socket.assigns.live_action, params)}
end

defp apply_action(socket, :index, _params), do: assign(socket, page_title: gettext("Banks"))
```

- The query is an assign named `<things>_query`: the `:list_search` action with the actor,
  the default sort and every `load:` the columns need. Cinder runs it, so `apply_action`
  only sets titles and the record a modal needs; it never reads the list.
- Select options for filters are read once in `mount` into `<thing>_options` assigns.

## The collection

```heex
<.list_search id="banks-search" params={@params} placeholder={gettext("Search by name or code")} />
<Cinder.collection
  id="banks"
  query={@banks_query}
  actor={@current_user}
  url_state={@url_state}
  page_size={[default: 20, options: [10, 20, 50, 100]]}
  search={false}
  show_filters={:toggle}
  sort_mode="exclusive"
  empty_message={gettext("No banks found")}
>
  <:col :let={bank} field="name" label={gettext("Name")} sort>{bank.name}</:col>
  <:col
    :let={bank}
    field="status"
    label={gettext("Status")}
    filter={[type: :select, options: Enum.map(BankStatus.values(), &{BankStatus.label(&1), &1}), prompt: gettext("All statuses")]}
  >
    {BankStatus.label(bank.status)}
  </:col>
  <:col :let={bank} label={gettext("Actions")}>...</:col>
  <:filter field="local_inserted_at_date" type="date_range" label={gettext("Date Created")} />
</Cinder.collection>
```

- Always `actor`, `url_state`, `sort_mode="exclusive"` and the 20-row page size above.
- `search={false}`: text search is `<.list_search>` above the collection feeding the
  resource's `:list_search` action (term + show archived), not Cinder's search box.
- `show_filters={:toggle}` when there are filters, `show_filters={false}` when there are none.
- `:let={record}` (Cinder yields the record, not a stream `{id, record}` tuple); every
  `label`, `prompt`, option label and `empty_message` goes through `gettext`.
- A sortable column has `field` and `sort`; relationship fields use dot notation
  (`field="client.name"`). The actions column is a plain `<:col label={gettext("Actions")}>`.
- A filter on a shown column goes on its `<:col filter=...>`; a filter on something not
  shown is a `<:filter>` slot. Date filters are `date_range` on the resource's
  `local_*_date` calculation.
- Per-row styling is `item_class={fn task -> if task.overdue, do: "text-red-600" end}`.
- Styling comes from the project's Cinder theme (`config :cinder, default_theme: ...,
  gettext_backend: ...`); do not pass `theme` or class overrides per collection.
- A card grid is `layout={:grid}` with an `<:item>` slot and `<:col field=... sort />` for the
  sort controls; give the item's root element its own `id` (grid items carry no
  `data-item-id`).

## Keeping it fresh

- After a form saves, the form component sends `send(self(), :bank_saved)` and the
  LiveView answers `handle_info(:bank_saved, socket)` with
  `Cinder.Refresh.refresh_table(socket, "banks")`. A patch alone no longer reloads the list.
- PubSub: publish on one resource-wide topic (`publish :update, "updated"`, not
  `["updated", :id]`), subscribe once in `mount`, and refresh the table. No per-row
  subscriptions, no `stream_insert`.

## Numbers over the filtered rows

Totals that must follow the user's filters come from `on_query_change`, which hands back
the filtered, unpaginated query:

```elixir
<Cinder.collection ... on_query_change={:leaves_query_changed}>

def handle_info({:leaves_query_changed, %{query: query}}, socket) do
  %{total_days: total_days} =
    Ash.aggregate!(query, [{:total_days, :sum, field: :amount}], actor: socket.assigns.current_user)

  {:noreply, assign(socket, total_days: total_days || 0)}
end
```

An export that must honour the same filters takes the page's URL params and rebuilds
them with `Cinder.Column.parse_columns/2`, `Cinder.UrlManager.decode_filters/2` and
`Cinder.QueryBuilder.apply_filters/3`, from one list of `{field, filter_type}` kept next
to the collection (see `PlangoraWeb.TimeEntryLive.Table.filter_query/2`).

## Tests

```elixir
{:ok, view, _html} = live(conn, ~p"/admin/banks?#{%{"status" => "active", "sort" => "name"}}")
render_async(view)
assert has_element?(view, "[data-item-id='#{bank.id}']")

view |> element("button[title='Go to page 2']") |> render_click()
render_async(view)
```

- Rows load asynchronously: call `render_async(view)` before asserting on them, and
  again after any search, click or save that reloads the list. Assertions on the `html`
  returned by `live/2` only see the loading state.
- Target rows with `[data-item-id='#{id}']`.
- Drive filters, sorting and pages through URL params (Cinder's own keys: the column
  `field`, `sort`, `page`, `page_size`), not by submitting the filter form.
- After a save the patched path is the bare list path (`~p"/admin/banks"`), with no
  `limit`/`offset`.
