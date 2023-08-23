defmodule EdenGarden.Repo do
  use Ecto.Repo,
    otp_app: :eden_garden,
    adapter: Ecto.Adapters.Postgres
end
