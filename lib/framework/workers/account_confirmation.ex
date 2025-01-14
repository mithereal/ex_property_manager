defmodule Framework.Workers.Mailer.Account.Confirmation do
  use Oban.Worker, queue: "email", max_attempts: 5, unique: [period: 30]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name, "email" => email} = _args}) do
    Framework.Mailer.Account.Confirmation.process(%{name: name, email: email})
  end

  @doc """
  Enqueues an Oban job to do start
  """
  @spec enqueue(Map.t(), :atom) :: {:ok, Job.t()} | {:error, Job.changeset()} | {:error, term()}
  def enqueue(args, :start) do
    args
    |> new(scheduled_at: args.start_time)
    |> Oban.insert!()
  end

  def enqueue(args, :end) do
    args
    |> new(scheduled_at: args.end_time)
    |> Oban.insert!()
  end

  def cancel(%{email: email}) do
    %Oban.Job{args: %{"email" => email}}
    |> Oban.cancel_job()

    %{email: email}
  end

  def cancel(%Oban.Job{} = job) do
    job
    |> Oban.cancel_job()

    job
  end

  def cancel(email) do
    %Oban.Job{args: %{"email" => email}}
    |> Oban.cancel_job()

    %Oban.Job{args: %{"email" => email}}
  end
end
