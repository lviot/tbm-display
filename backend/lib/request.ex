defmodule Tbm.Request do
  @spec base_url!() :: URI.t()
  def base_url!(), do: URI.parse(Application.fetch_env!(:tbm, :base_url))

  # @spec request(Atom.t(), String.t()) :: Req.Response.t() | Exception.t()
  def request(method, path, opts \\ []) do
    qs =
      opts
      |> Keyword.get(:qs, %{})
      |> URI.encode_query()
    url =
      base_url!()
      |> URI.append_path(path)
      |> URI.append_query(qs)
    req = Req.new([
      method: method,
      url: url,
      decode_json: [keys: :atoms],
    ])
    {_req, resp} = Req.run(req)
    resp
  end
end