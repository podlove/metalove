defmodule Metalove.FetcherCache do
  use GenServer
  @moduledoc false

  @cache __MODULE__

  defstruct table_name: @cache,
            log_limit: 1_000_000

  def start_link(opts \\ []) do
    GenServer.start_link(
      @cache,
      %__MODULE__{},
      [name: @cache] ++ opts
    )
  end

  def get(key) do
    case GenServer.call(@cache, {:get, key}) do
      [] -> {:not_found}
      [{_key, result}] -> {:found, result}
    end
  end

  def set(key, value) do
    GenServer.cast(@cache, {:set, key, value})
  end

  def purge() do
    GenServer.cast(@cache, :purge)
  end

  # GenServer callbacks

  require Logger

  @impl true
  def handle_call({:get, key}, _from, state) do
    result = :ets.lookup(state.table_name, key)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:set, key, value}, state) do
    Logger.debug("Fetcher_Cache storing: #{inspect(key)}")
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
