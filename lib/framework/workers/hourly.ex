defmodule Framework.Workers.Hourly do
  use Oban.Worker, queue: "system", max_attempts: 5, unique: [period: 30]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => _id} = _args}) do
    try do
      Framework.Application.Setup.setup()
      :ok
    catch
      _ -> :error
    end
  end

  @doc """
  Enqueues an Oban job to do something
  """
  # @spec enqueue(Track.t(), :atom) ::
  #    {:ok, Job.t()} | {:error, Job.changeset()} | {:error, term()}
  def enqueue(args, :start) do
    params =
      args
      |> new(schedule_in: args.schedule_in)

    Oban.insert!(Framework.Oban, params)
  end

  def enqueue(args, :end) do
    params =
      args
      |> new(scheduled_at: args.end_time)

    Oban.insert!(Framework.Oban, params)
  end

  def cancel(%{id: id}) do
    params = %Oban.Job{args: %{"id" => id}}
    Oban.cancel_job(Framework.Oban, params)

    %{id: id}
  end

  def cancel(%Oban.Job{} = job) do
    Oban.cancel_job(Framework.Oban, job)

    # Server.shutdown(%{"id" => job.id})

    job
  end

  def cancel(id) do
    params = %Oban.Job{args: %{"id" => id}}
    Oban.cancel_job(Framework.Oban, params)

    %Oban.Job{args: %{"id" => id}}
  end
end
