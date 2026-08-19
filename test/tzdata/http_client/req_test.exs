defmodule Tzdata.HTTPClient.ReqTest do
  use ExUnit.Case, async: true

  alias Tzdata.HTTPClient.Req, as: ReqClient

  @url "http://example.test"

  describe "get/3" do
    test "given a successful response, when GET is called, then it returns the HTTP client tuple" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-response-header", "response-value")
        |> Plug.Conn.send_resp(200, "response body")
      end)

      assert {:ok, {200, headers, "response body"}} =
               ReqClient.get(@url, [], req_options())

      assert {"x-response-header", "response-value"} in headers
    end

    test "given a redirect, when follow_redirect is true, then it returns the final response" do
      Req.Test.stub(__MODULE__, fn
        %{request_path: "/redirect"} = conn ->
          Req.Test.redirect(conn, to: "/final")

        %{request_path: "/final"} = conn ->
          Plug.Conn.send_resp(conn, 200, "redirected")
      end)

      options = req_options(follow_redirect: true)

      assert {:ok, {200, headers, "redirected"}} =
               ReqClient.get(@url <> "/redirect", [], options)

      assert is_list(headers)
    end

    test "given a redirect, when follow_redirect is false, then it returns the redirect response" do
      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.redirect(conn, to: "/final")
      end)

      options = req_options(follow_redirect: false)

      assert {:ok, {302, headers, _body}} =
               ReqClient.get(@url <> "/redirect", [], options)

      assert {"location", "/final"} in headers
    end

    test "given custom headers, when GET is called, then it sends those headers" do
      test_pid = self()

      Req.Test.stub(__MODULE__, fn conn ->
        send(test_pid, {:request_headers, conn.req_headers})
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      assert {:ok, {200, _response_headers, "ok"}} =
               ReqClient.get(@url, [{"X-Custom-Header", "test-value"}], req_options())

      assert_received {:request_headers, headers}
      assert {"x-custom-header", "test-value"} in headers
    end

    test "given repeated response headers, when GET is called, then it preserves every value" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.prepend_resp_headers([
          {"set-cookie", "first=value"},
          {"set-cookie", "second=value"}
        ])
        |> Plug.Conn.send_resp(200, "ok")
      end)

      assert {:ok, {200, headers, "ok"}} = ReqClient.get(@url, [], req_options())
      assert {"set-cookie", "first=value"} in headers
      assert {"set-cookie", "second=value"} in headers
    end
  end

  describe "head/3" do
    test "given a successful response, when HEAD is called, then it returns status and headers" do
      test_pid = self()

      Req.Test.stub(__MODULE__, fn conn ->
        send(test_pid, {:request_method, conn.method})

        conn
        |> Plug.Conn.put_resp_header("content-length", "123")
        |> Plug.Conn.send_resp(200, "")
      end)

      assert {:ok, {200, headers}} = ReqClient.head(@url, [], req_options())

      assert_received {:request_method, "HEAD"}
      assert {"content-length", "123"} in headers
    end

    test "given a transport error, when HEAD is called, then it returns the error" do
      Req.Test.stub(__MODULE__, &Req.Test.transport_error(&1, :econnrefused))

      assert {:error, %Req.TransportError{reason: :econnrefused}} =
               ReqClient.head(@url, [], req_options())
    end
  end

  defp req_options(options \\ []) do
    Keyword.merge([plug: {Req.Test, __MODULE__}, retry: false], options)
  end
end
