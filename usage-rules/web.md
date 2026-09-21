# Phoenix and LiveView

## Components, not raw elements

Owner: "we should replace all `<button>` with `<.button>` as we have a working button
implementation already", "please scan for all `a` and replace with a component in
`Plangora.Components.Buttons` or `<.link>`", "replace select with the `<.input>` component".

Read the project's `components/buttons.ex` and `core_components.ex` first and pick the
variant (`<.button>`, `<.primary_link>`, `<.secondary_button>`, `<.ghost_button>`,
`<.input type="select">`, `<.input type="textarea">`). Hidden inputs and
`live_file_input` stay as they are.

## :if and :for

"use the `:if` on the `<p>` tag", "use `:for`":

```heex
<%!-- BAD --%>
<%= if @board do %><p>...</p><% end %>
<%= for item <- @items do %><li>...</li><% end %>

<%!-- GOOD --%>
<p :if={@board}>...</p>
<li :for={item <- @items}>...</li>
```

## gettext everywhere

"Let's make sure all text in templates is using gettext", "All text should be gettext":
labels, headings, button text, flash messages, aria-labels, select options, and error
strings raised from resources.

## Localize for dates, times, numbers and money

"this should be using `Localize.DateTime.to_string/2`", "for money, i believe we can
use `Localize.Currency.display_name!/2`". Never `Calendar.strftime` or string
concatenation for a timestamp. People are shown by `display_name` ("let's always rely
on a user's `display_name` when referring to a user").

## Forms

"shouldn't this be using a form instead of changeset?", "we should be using form and use
`prepare_params` for this", "pass in the `field` for these", "we can just use mode to
set the form, no?". Build `AshPhoenix.Form.for_create/for_update`, bind inputs with
`field={@form[:name]}`, derive hidden values in `prepare_params`, and switch variants
with a `mode` assign instead of duck-typing params.

A form with `live_file_input` needs `phx-change` or uploads never start.

## Handlers

- No nested `case`; flatten with `with`.
- Validate request params against the enum's values before `String.to_existing_atom/1`.
- Assign once: `assign(socket, a: 1, b: 2)` ("let's use 1 inline `assign` instead of so many").
- Pattern-match flash tuples and results instead of `if`.
- Components take individual values, not whole structs ("let's not pass in the struct,
  let's pass in each piece of data by itself").

## Routing

Admin-only screens live under `/admin` ("if these are for admins, we should just move
these to `/admin` namespace"); feature areas are scoped under their namespace. Routes of
identical shape shadow each other in declaration order.
