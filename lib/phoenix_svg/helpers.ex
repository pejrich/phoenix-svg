defmodule PhoenixSVG.Helpers do
  @moduledoc false

  # List all of the SVG files in the given directory.
  #
  # Returns a list of all the files, and an MD5 hash of the list so it can be determined if the list
  # changed and needs to be re-compiled.
  def list_files(path) do
    files =
      path
      |> Path.join("**/*.svg")
      |> Path.wildcard()
      |> Enum.sort()

    {files, :erlang.md5(files)}
  end

  # Reads a file and parses out the name and path.
  #
  # The name will be the filename without the extension, and the path will be a list of directory
  # names the file is nested in relative to the base path.
  def read_file!(filepath, basepath) do
    name = Path.basename(filepath) |> Path.rootname()
    id = "phoenix_svg__#{name}"
    content = File.read!(filepath) |> String.trim()
    [h, t] = String.split(content, "<svg", parts: 2)
    view_box = Regex.run(~r/^[^>]+\KviewBox="[^"]+"/, t) |> List.wrap()

    sym = h <> "<symbol id=\"#{id}\" " <> t
    sym = Regex.split(~r[(</svg>)(?!.*\1)], sym) |> then(fn [h, t] -> h <> "</symbol>" <> t end)

    sym =
      [
        "<svg xmlns=\"http://www.w3.org/2000/svg\" style=\"display:none\"> ",
        sym,
        "</svg>",
        "<svg #{view_box} "
      ]
      |> Enum.join("")

    content = [sym, "<svg #{view_box} ", "><use href=\"##{id}\"></svg>"]

    rel_path = Path.relative_to(filepath, basepath)

    path =
      rel_path
      |> Path.dirname()
      |> Path.split()
      |> Enum.reject(&(&1 == "."))

    {name, path, content}
  end

  # Converts a map or keyword list into HTML-safe attributes.
  #
  # Any keys that contain an underscore will be converted to a dash in the HTML attribute. For
  # example, `%{foo_bar: "baz"}` will result in the attribute `foo-bar="baz"`.
  def to_safe_html_attrs(data) do
    for {key, value} <- data do
      key =
        key
        |> Atom.to_string()
        |> String.replace("_", "-")
        |> Phoenix.HTML.Safe.to_iodata()

      [key, ?=, ?", Phoenix.HTML.Safe.to_iodata(value), ?", ?\s]
    end
  end
end
