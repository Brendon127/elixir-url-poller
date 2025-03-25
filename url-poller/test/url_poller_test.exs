defmodule UrlPollerTest do
  use ExUnit.Case
  doctest UrlPoller

  test "greets the world" do
    assert UrlPoller.hello() == :world
  end
end
