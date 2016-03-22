defmodule MaxwellTest do
  use ExUnit.Case
  doctest Maxwell

  defmodule ClientWithAdapterFun do
    use Maxwell.Builder

    adapter fn (env) ->
      {:ok, %{env | status: 201, headers: %{}, body: "function adapter"}}
    end
  end

  defmodule ModuleAdapter do
    def call(env) do
      {:ok, %{env | status: 202}}
    end
  end

  defmodule ClientWithAdapterMod do
    use Maxwell.Builder

    adapter ModuleAdapter
  end

  test "client with adapter as function fn(x) -> x end" do
    {:ok, result} = ClientWithAdapterFun.get()
    assert result.status == 201
  end

  test "client with adapter as module" do
    {:ok, result} = ClientWithAdapterMod.get()
    assert result.status == 202
  end

  defmodule Client do
    use Maxwell.Builder

    adapter fn (env) ->
      {:ok, %{env|status: 200, headers: %{'Content-Type' => 'text/plain'}, body: "body"}}
    end
  end

  test "return :status 200" do
    {:ok, result} = Client.get()
    assert result.status == 200
  end

  test "return content type header" do
    {:ok, result} = Client.get()
    assert result.headers == %{'Content-Type' => 'text/plain'}
  end

  test "return 'body' as body" do
    {:ok, result} = Client.get()
    assert result.body == "body"
  end

  test "GET request" do
    {:ok, result} = Client.get()
    result1 = Client.get!()
    assert result.method == :get
    assert result1.method == :get
  end

  test "HEAD request" do
    {:ok, result} = Client.head()
    result1 = Client.head!()
    assert result.method == :head
    assert result1.method == :head
  end

  test "POST request" do
    {:ok, result} = Client.post()
    result1 = Client.post!()
    assert result.method == :post
    assert result1.method == :post
  end

  test "PUT request" do
    {:ok, result} = Client.put()
    result1 = Client.put!()
    assert result.method == :put
    assert result1.method == :put
  end

  test "PATCH request" do
    {:ok, result} = Client.patch()
    result1 = Client.patch!()
    assert result.method == :patch
    assert result1.method == :patch
  end

  test "DELETE request" do
    {:ok, result} = Client.delete()
    result1 = Client.delete!()
    assert result.method == :delete
    assert result1.method == :delete
  end

  test "TRACE request" do
    {:ok, result} = Client.trace()
    result1 = Client.trace!()
    assert result.method == :trace
    assert result1.method == :trace
  end

  test "OPTIONS request" do
    {:ok, result} = Client.options()
    result1 = Client.options!()
    assert result.method == :options
    assert result1.method == :options
  end

  test "path + query" do
    assert Client.get!([url: "/foo", query: %{a: 1, b: "foo"}]).url == "/foo?a=1&b=foo"
  end

  test "path with query + query" do
    assert Client.get!([url: "/foo?c=4", query: %{a: 1, b: "foo"}]).url == "/foo?c=4&a=1&b=foo"
  end

end

defmodule MiddlewareTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder, ~w(get post)

    middleware Maxwell.Middleware.BaseUrl, "http://example.com"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
    middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/json"}
    middleware Maxwell.Middleware.EncodeJson
    middleware Maxwell.Middleware.DecodeJson

    adapter fn (env) ->
      cond do
        List.last(String.split(env.url, "/")) == "secret" ->
          {:ok, %{env| status: 200, headers: %{}, body: env.headers['Authorization']}}
        true ->
          if env.body == "{\"key2\":201,\"key1\":101}" do
           {:ok, %{env| status: 200, headers: %{'Content-Type' => "application/json"}, body: "{\"key2\":101,\"key1\":201}"}}
          else
            {:ok, %{env| status: 200, headers: %{'Content-Type' => "application/json"}, body: "{\"key2\":2,\"key1\":1}"}}
          end
      end
    end

  end

  test "make use of base url" do
    assert Client.get!().url == "http://example.com"
  end

  test "make use of options" do
    assert Client.post!().opts == [connect_timeout: 3000]
  end

  test "make use of headers" do
    assert Client.get!().headers == %{'Content-Type' => "application/json"}
  end

  test "make use of endeodejson" do
    assert Client.post!([body: %{"key1" => 101, "key2" => 201}]).body == %{"key2" => 101, "key1" => 201}
  end

  test "make use of deodejson" do
    assert Client.post!().body == %{"key2" => 2, "key1" => 1}
  end

end
