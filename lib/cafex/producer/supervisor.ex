defmodule Cafex.Producer.Supervisor do
  @moduledoc """
  Manage producers under the supervisor tree.
  """

  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  @spec start_producer(producer :: atom, Cafex.Producer.options) :: {:ok, producer :: atom} |
                                                                    {:error, reason :: term}
  def start_producer(producer, opts) do
    case Supervisor.start_child __MODULE__, [producer, opts] do
      {:ok, _pid, ^producer} -> {:ok, producer}
      {:error, reason} -> {:error, reason}
    end
  end

  defdelegate stop_producer(name), to: Cafex.Producer, as: :stop

  @doc false
  def init([]) do
    children = [
      worker(Cafex.Producer, [], restart: :temporary,
                                shutdown: 2000)
    ]
    supervise children, strategy: :simple_one_for_one,
                    max_restarts: 10,
                     max_seconds: 60
  end
end
