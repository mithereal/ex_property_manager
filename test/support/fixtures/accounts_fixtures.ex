defmodule Framework.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Framework.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        active: true,
        email: "some email"
      })
      |> Framework.Accounts.create_account()

    account
  end
end
