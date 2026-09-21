defmodule PlangoraElixirRules.Check.Helpers do
  @moduledoc false
  # Small AST helpers shared by the checks. Everything here is purely
  # syntactic: it reads the source as written, never the compiled DSL.

  alias Credo.SourceFile

  @doc "Entity calls named `name` (or any of `names`) anywhere inside `ast`, in source order."
  def entity_calls(ast, names) when is_list(names) do
    {_, found} =
      Macro.prewalk(ast, [], fn
        {name, meta, args} = node, acc when is_atom(name) and is_list(args) ->
          if name in names and Keyword.has_key?(meta, :line),
            do: {node, [node | acc]},
            else: {node, acc}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(found)
  end

  def entity_calls(ast, name), do: entity_calls(ast, [name])

  @doc """
  The options of a DSL entity call, merging the trailing keyword list with
  `option value` lines inside its `do` block, so `belongs_to :x, Y, public?: true`
  and `belongs_to :x, Y do public? true end` read the same.
  """
  def entity_options({_name, _meta, args}) when is_list(args) do
    {do_block, rest} = split_do_block(args)

    keyword =
      case List.last(rest) do
        kw when is_list(kw) -> if Keyword.keyword?(kw), do: kw, else: []
        _ -> []
      end

    block_opts =
      do_block
      |> block_statements()
      |> Enum.flat_map(fn
        {key, _, [value]} when is_atom(key) -> [{key, value}]
        _ -> []
      end)

    Keyword.merge(keyword, block_opts)
  end

  def entity_options(_), do: []

  @doc "The first positional argument of an entity call, when it is an atom (the entity's name)."
  def entity_name({_name, _meta, [first | _]}) when is_atom(first), do: first
  def entity_name(_), do: nil

  @doc "Line number of an AST node, or `default`."
  def line(node, default \\ 1)
  def line({_, meta, _}, default) when is_list(meta), do: Keyword.get(meta, :line, default)
  def line(_, default), do: default

  @doc "Every `~H` sigil in the file as `{line, string}`; interpolations are dropped."
  def heex_sigils(%SourceFile{} = source_file) do
    source_file
    |> SourceFile.ast()
    |> heex_sigils()
  end

  def heex_sigils(ast) do
    {_, found} =
      Macro.prewalk(ast, [], fn
        {:sigil_H, meta, [{:<<>>, _, parts}, _mods]} = node, acc ->
          text = parts |> Enum.filter(&is_binary/1) |> Enum.join("")
          {node, [{Keyword.get(meta, :line, 1), text} | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(found)
  end

  @doc """
  Scans `text` (starting at `first_line`) with `regex`; returns `{line, match}`
  per hit, so an issue can point at the right line inside a multi-line sigil.
  """
  def scan_lines(text, first_line, regex) do
    text
    |> String.split("\n")
    |> Enum.with_index(first_line + 1)
    |> Enum.flat_map(fn {line_text, line} ->
      regex
      |> Regex.scan(line_text)
      |> Enum.map(fn [match | _] -> {line, match} end)
    end)
  end

  @doc "True when `filename` is under a test directory."
  def test_file?(filename), do: AshCredo.PathFilter.excluded?(filename, [~r"/test/", "test"])

  @doc "True when `filename` is in the Phoenix web layer (`lib/*_web/`)."
  def web_file?(filename), do: String.contains?(filename, "_web/")

  defp split_do_block(args) do
    case List.last(args) do
      [{:do, block} | _] = kw when is_list(kw) -> {block, Enum.drop(args, -1)}
      _ -> {nil, args}
    end
  end

  defp block_statements(nil), do: []
  defp block_statements({:__block__, _, statements}), do: statements
  defp block_statements(statement), do: [statement]
end
