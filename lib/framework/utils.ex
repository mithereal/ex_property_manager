defmodule Framework.Utils do
  alias Framework.Utils

  def suffix_date(date) do
    case date.day do
      1 -> "st"
      21 -> "st"
      31 -> "st"
      2 -> "nd"
      22 -> "nd"
      3 -> "rd"
      23 -> "rd"
      _ -> "th"
    end
  end

  def date_name_format(date, tz \\ "America/Phoenix") do
    today = Timex.now(tz) |> DateTime.to_date()
    tomorrow = today |> Timex.shift(days: 1)

    case date do
      date when date == today -> "Today"
      date when date == tomorrow -> "Tomorrow"
      _ -> to_string(date)
    end
  end

  def date_range_names(number_of_days, tz \\ "America/Phoenix") do
    today = Timex.now(tz) |> DateTime.to_date()
    to = Date.utc_today() |> Timex.shift(days: number_of_days)
    tomorrow = today |> Timex.shift(days: 1)

    Date.range(today, to)
    |> Enum.to_list()
    |> Enum.map(fn x ->
      dayname = x |> Timex.weekday() |> Timex.day_shortname()

      case x do
        x when x == today -> {"Today", x, Utils.suffix_date(x)}
        x when x == tomorrow -> {"Tomorrow", x, Utils.suffix_date(x)}
        _ -> {dayname, x, Utils.suffix_date(x)}
      end
    end)
  end

  def convert_date_to_datetime(%DateTime{} = date), do: date

  def convert_date_to_datetime(%Date{} = date) do
    date
    |> Date.to_gregorian_days()
    |> Kernel.*(86400)
    |> Kernel.+(86399)
    |> DateTime.from_gregorian_seconds()
  end
end
