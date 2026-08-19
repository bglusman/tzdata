defmodule Tzdata.HTTPClient.Req do
  @moduledoc false

  @behaviour Tzdata.HTTPClient

  @impl true
  def get(url, headers, options) do
    case request(:get, url, headers, options) do
      {:ok, %Req.Response{status: status, body: body} = response} ->
        {:ok, {status, Req.get_headers_list(response), body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def head(url, headers, options) do
    case request(:head, url, headers, options) do
      {:ok, %Req.Response{status: status} = response} ->
        {:ok, {status, Req.get_headers_list(response)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp request(method, url, headers, options) do
    {follow_redirect, req_options} = Keyword.pop(options, :follow_redirect, false)

    req_options =
      Keyword.merge(req_options,
        method: method,
        url: url,
        headers: headers,
        redirect: follow_redirect,
        decode_body: false
      )

    Req.request(req_options)
  end
end
