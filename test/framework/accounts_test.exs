defmodule Framework.AccountsTest do
  use Framework.DataCase

  alias Framework.Accounts

  describe "accounts" do
    alias Framework.Accounts.Account

    import Framework.AccountsFixtures

    @invalid_attrs %{active: nil, email: nil}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture() |> Map.delete(:admin_user)

      assert Accounts.get_account!(account.id) |> Map.delete(:admin_user) ==
               account |> Map.delete(:admin_user)
    end

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{active: true, email: "some email"}

      assert {:ok, %Account{} = account} = Accounts.create_account(valid_attrs)
      assert account.active == true
      assert account.email == "some email"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      update_attrs = %{active: false, email: "some updated email"}

      assert {:ok, %Account{} = account} = Accounts.update_account(account, update_attrs)
      assert account.active == false
      assert account.email == "some updated email"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture() |> Map.delete(:admin_user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id) |> Map.delete(:admin_user)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end
end
