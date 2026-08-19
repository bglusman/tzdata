defmodule Tzdata.HTTPClient.Hackney do
  @moduledoc false

  @behaviour Tzdata.HTTPClient

  @message """
  missing :hackney dependency

  Tzdata requires a HTTP client in order to automatically update timezone
  database.

  In order to use the built-in adapter based on Hackney HTTP client, add the
  following to your mix.exs dependencies list:

      {:hackney, "~> 1.0 or ~> 4.0"}

  See README for more information.
  """

  @impl true
  def get(url, headers, options) do
    ensure_hackney!()

    with {:ok, status, response_headers, client_ref} <-
           apply(:hackney, :get, [url, headers, "", options]),
         {:ok, body} <- apply(:hackney, :body, [client_ref]) do
      {:ok, {status, response_headers, body}}
    end
  end

  @impl true
  def head(url, headers, options) do
    ensure_hackney!()

    with {:ok, status, response_headers} <-
           apply(:hackney, :head, [url, headers, "", options]) do
      {:ok, {status, response_headers}}
    end
  end

  defp ensure_hackney! do
    if Code.ensure_loaded?(:hackney), do: :ok, else: raise(@message)
  end
end
