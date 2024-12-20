# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.FrontendTest do
  use Pleroma.DataCase
  alias Mix.Tasks.Pleroma.Frontend

  import ExUnit.CaptureIO, only: [capture_io: 1]

  @dir "test/frontend_static_test"

  setup do
    File.mkdir_p!(@dir)
    clear_config([:instance, :static_dir], @dir)

    on_exit(fn ->
      File.rm_rf(@dir)
    end)
  end

  test "it downloads and unzips a known frontend" do
    clear_config([:frontends, :available], %{
      "pleroma" => %{
        "ref" => "fantasy",
        "name" => "pleroma",
        "build_url" => "http://gensokyo.2hu/builds/${ref}"
      }
    })

    Tesla.Mock.mock(fn %{url: "http://gensokyo.2hu/builds/fantasy"} ->
      %Tesla.Env{status: 200, body: File.read!("test/fixtures/tesla_mock/frontend_dist.zip")}
    end)

    capture_io(fn ->
      Frontend.run(["install", "pleroma"])
    end)

    assert File.exists?(Path.join([@dir, "frontends", "pleroma", "fantasy", "test.txt"]))
  end

  test "it enables a frontend with the --primary flag" do
    frontend = %Pleroma.Frontend{
      ref: "fantasy",
      name: "pleroma",
      build_url: "http://gensokyo.2hu/builds/${ref}"
    }

    map = Pleroma.Frontend.to_map(frontend)
    clear_config(:configurable_from_database, true)
    clear_config([:frontends, :available], %{"pleroma" => map})

    Tesla.Mock.mock(fn %{url: "http://gensokyo.2hu/builds/fantasy"} ->
      %Tesla.Env{status: 200, body: File.read!("test/fixtures/tesla_mock/frontend_dist.zip")}
    end)

    capture_io(fn ->
      Frontend.run(["install", "pleroma", "--primary"])
    end)

    assert Pleroma.Config.get([:frontends, :primary]) == map
  end

  test "it also works given a file" do
    clear_config([:frontends, :available], %{
      "pleroma" => %{
        "ref" => "fantasy",
        "name" => "pleroma",
        "build_dir" => ""
      }
    })

    folder = Path.join([@dir, "frontends", "pleroma", "fantasy"])
    previously_existing = Path.join([folder, "temp"])
    File.mkdir_p!(folder)
    File.write!(previously_existing, "yey")
    assert File.exists?(previously_existing)

    capture_io(fn ->
      Frontend.run(["install", "pleroma", "--file", "test/fixtures/tesla_mock/frontend.zip"])
    end)

    assert File.exists?(Path.join([folder, "test.txt"]))
    refute File.exists?(previously_existing)
  end

  test "it downloads and unzips unknown frontends" do
    Tesla.Mock.mock(fn %{url: "http://gensokyo.2hu/madeup.zip"} ->
      %Tesla.Env{status: 200, body: File.read!("test/fixtures/tesla_mock/frontend.zip")}
    end)

    capture_io(fn ->
      Frontend.run([
        "install",
        "unknown",
        "--ref",
        "baka",
        "--build-url",
        "http://gensokyo.2hu/madeup.zip",
        "--build-dir",
        ""
      ])
    end)

    assert File.exists?(Path.join([@dir, "frontends", "unknown", "baka", "test.txt"]))
  end

  describe "enable" do
    setup do
      clear_config(:configurable_from_database, true)
    end

    test "enabling a primary frontend" do
      capture_io(fn -> Frontend.run(["enable", "ordo"]) end)

      primary = Pleroma.Config.get([:frontends, :primary])
      assert primary["name"] == "ordo"
    end

    test "enabling an admin frontend" do
      capture_io(fn -> Frontend.run(["enable", "ordo", "--admin"]) end)

      primary = Pleroma.Config.get([:frontends, :admin])
      assert primary["name"] == "ordo"
    end

    test "raise if configurable_from_database is disabled" do
      clear_config(:configurable_from_database, false)

      assert_raise(RuntimeError, fn ->
        capture_io(fn -> Frontend.run(["enable", "ordo"]) end)
      end)
    end
  end
end
