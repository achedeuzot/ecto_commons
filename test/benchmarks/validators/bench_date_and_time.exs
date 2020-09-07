types = %{birthdate: :date, created_at: :utc_datetime, meeting_start: :time}

params = %{
  birthdate: ~D[2016-05-24],
  created_at: ~U[2016-05-24 13:26:08Z],
  meeting_start: ~T[12:01:01]
}

changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))

Benchee.run(%{
  "validate_date" => fn ->
    EctoCommons.DateValidator.validate_date(changeset, :birthdate, before: ~D[2017-05-24])
  end,
  "validate_time" => fn ->
    EctoCommons.TimeValidator.validate_time(changeset, :meeting_start, before: ~T[13:01:01])
  end,
  "validate_datetime" => fn ->
    EctoCommons.DateTimeValidator.validate_datetime(changeset, :created_at,
      before: ~U[2017-05-24 00:00:00Z]
    )
  end
})
