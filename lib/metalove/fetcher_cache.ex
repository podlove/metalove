defmodule Metalove.FetcherCache do
  use GenServer
  @moduledoc false

  defstruct table_name: :metalove_fetcher_cache,
            log_limit: 1_000_000

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %__MODULE__{},
      [name: __MODULE__] ++ opts
    )
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

  # GenServer callbacks

  require Logger

  def handle_call({:get, key}, _from, state) do
    result = :ets.lookup(state.table_name, key)
    {:reply, result, state}
  end

  def handle_call({:set, key, value}, _from, state) do
    Logger.debug("Fetcher_Cache storing: #{inspect(key)}")
    true = :ets.insert(state.table_name, {key, value})
    {:reply, value, state}
  end

  def init(initial_state) do
    :ets.new(initial_state.table_name, [:named_table, :set, :private])

    {:ok, initial_state}
  end
end
