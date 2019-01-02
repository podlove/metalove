defmodule Metalove.Repository do
  use GenServer

  defstruct table_name: :metalove_repository,
            log_limit: 1_000_000

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %__MODULE__{},
      [name: __MODULE__] ++ opts
    )
  end

  def fetch(key, default_value_function) do
    case get(key) do
      {:not_found} -> set(key, default_value_function.())
      {:found, result} -> result
    end
  end

  def get(key) do
    case GenServer.call(__MODULE__, {:get, key}) do
      [] -> {:not_found}
      [{_key, result}] -> {:found, result}
    end
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def put_podcast(%Metalove.Podcast{id: id} = value) do
    GenServer.call(__MODULE__, {:set, {:podcast, id}, value})
  end

  def put_feed(%Metalove.PodcastFeed{feed_url: feed_url} = value) do
    GenServer.call(__MODULE__, {:set, {:feed, feed_url}, value})
  end

  def put_episode(%Metalove.Episode{feed_url: feed_url, guid: guid} = value) do
    GenServer.call(__MODULE__, {:set, {:episode, feed_url, guid}, value})
  end

  # GenServer callbacks

  def handle_call({:get, key}, _from, state) do
    result = :ets.lookup(state.table_name, key)
    {:reply, result, state}
  end

  def handle_call({:set, key, value}, _from, state) do
    true = :ets.insert(state.table_name, {key, value})
    {:reply, value, state}
  end

  def init(initial_state) do
    :ets.new(initial_state.table_name, [:named_table, :set, :private])

    {:ok, initial_state}
  end
end
