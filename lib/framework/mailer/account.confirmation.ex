defmodule Framework.Mailer.Account.Confirmation do
  import Swoosh.Email

  use Phoenix.Swoosh,
    template_root: Application.app_dir(:framework, "priv"),
    template_path: "mailer"

  @sender Application.compile_env(:framework, :sender) || "test"
  @domain Application.compile_env(:framework, :domain) || "example.com"

  defp premail(email) do
    html = Premailex.to_inline_css(email.html_body)
    text = Premailex.to_text(email.html_body)

    email
    |> html_body(html)
    |> text_body(text)
  end

  def process(user, subject \\ "Welcome to our Site!", sender \\ @sender, domain \\ @domain) do
    new()
    |> to({user.name, user.email})
    |> from({sender, "no-reply@#{domain}"})
    |> subject(subject)
    |> render_body("account_confirmation.html", %{username: user.name})
    |> premail()
  end

  def queue({name, email}) do
    start_time = DateTime.utc_now() |> DateTime.add(1, :minute)
    job = %{start_at: start_time, email: email, name: name}

    Framework.Workers.Mailer.Account.Confirmation.enqueue(job, :start)
  end
end
