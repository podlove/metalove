defmodule Metalove.Repository do
  use GenServer

  @moduledoc false

  @repo __MODULE__

  defstruct table_name: :metalove_repository,
            log_limit: 1_000_000

  def start_link(opts \\ []) do
    GenServer.start_link(
      @repo,
      %__MODULE__{},
      [name: @repo] ++ opts
    )
  end

  # TODO: rename, because it fetches AND stores
  def fetch(key, default_value_function) do
    case get(key) do
      {:not_found} -> set(key, default_value_function.())
      {:found, result} -> result
    end
  end

  def get(key) do
    case GenServer.call(@repo, {:get, key}) do
      [] -> {:not_found}
      [{_key, result}] -> {:found, result}
    end
  end

  require Logger

  def set(key, value) do
    GenServer.cast(@repo, {:set, key, value})
    value
  end

  def purge() do
    GenServer.cast(@repo, :purge)
  end

  # internal conveninence

  def put_podcast(%Metalove.Podcast{id: id, main_feed_url: feed_url} = value) do
    set({:podcast, id}, value)
    set({:url, id}, feed_url)
    value
  end

  def put_feed(%Metalove.PodcastFeed{feed_url: feed_url} = value) do
    set({:feed, feed_url}, value)
  end

  def put_episode(%Metalove.Episode{feed_url: feed_url, guid: guid} = value) do
    set({:episode, feed_url, guid}, value)
  end

  # GenServer callbacks

  @impl true
  def handle_call({:get, key}, _from, state) do
    result = :ets.lookup(state.table_name, key)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:set, key, value}, state) do
    Logger.debug("Storing: #{inspect(key)}")
    true = :ets.insert(state.table_name, {key, value})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:purge, state) do
    :ets.delete_all_objects(state.table_name)
    {:noreply, state}
  end

  @impl true
  def init(initial_state) do
    :ets.new(initial_state.table_name, [:named_table, :set, :private])

    {:ok, initial_state}
  end
end
