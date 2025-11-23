defmodule Tbm.StopArea do
  @type t :: %__MODULE__{
               id: String.t(),
               detailedLabel: String.t(),
               name: String.t(),
               type: String.t(),
               lines: list(Tbm.Line.t()),
             }

  @keys [:id, :detailedLabel, :name, :type, :lines]
  @enforce_keys @keys
  defstruct @keys

  def new(%{lines: _} = args) do
    lines = Enum.map(args.lines, &Tbm.Line.new/1)
    struct(__MODULE__, %{args | lines: lines})
  end
end


defmodule Tbm.Line do
  @typedoc """
  "TRAMWAY" | "BUS" | "TRAIN" | "REGIONAL_BUS"
  """
  @type mode :: String.t

  @type t :: %__MODULE__{
    id: String.t(),
    code: String.t(),
    name: String.t(),
    isOperating: boolean(),
    isSpecial: boolean(),
    mode: mode(),
    style: %{
      color: String.t(),
      textColor: String.t(),
    },
  }

  @keys [:code, :id, :isOperating, :isSpecial, :mode, :name, :style]
  defstruct @keys

  def new(line), do: struct(__MODULE__, line)
end

defmodule Tbm.Route do
  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
  }

  @keys [:id, :name]
  @enforce_keys @keys
  defstruct @keys

  def new(args), do: struct(__MODULE__, args)
end

defmodule Tbm.Direction do
  @type t :: %__MODULE__{
    line: Tbm.Line.t(),
    route: Tbm.Route.t(),
  }

  @keys [:line, :route]
  @enforce_keys @keys
  defstruct @keys

  def new(args) do
    struct(__MODULE__, %{
      line: Tbm.Line.new(args.line),
      route: Tbm.Route.new(args.route),
    })
  end
end

defmodule Tbm.TrafficInfoEvent do
  @type t :: %__MODULE__{
    title: String.t(),
    severity: String.t(),
    endDate: String.t(),
    startDate: String.t(),
  }

  defstruct [:title, :severity, :endDate, :startDate]

  def new(args), do: struct(__MODULE__, args)
end

defmodule Tbm.Departure do
  @type t :: %__MODULE__{
    id: String.t(),
    line: Tbm.Line.t(),
    route: Tbm.Route.t(),
    departure: String.t(),
    isRealTime: boolean(),
    vehiclePosition: %{
      latitude: float(),
      longitude: float(),
    },
  }

  @keys [:id, :line, :route, :departure, :isRealTime, :vehiclePosition]
  @enforce_keys @keys
  defstruct @keys

  def new(args) do
    {:ok, departure, _} = DateTime.from_iso8601(args.departure)
    tz = Application.get_env(:tbm, :timezone)

    struct(__MODULE__, %{
      args |
      line: Tbm.Line.new(args.line),
      route: Tbm.Route.new(args.route),
      departure: DateTime.shift_zone!(departure, tz),
    })
  end
end

defmodule Tbm.Timetable do
  @type t :: %__MODULE__{
    nextDepartures: list(Tbm.Line.t()),
    trafficInfoEvents: list(Tbm.TrafficInfoEvent.t()),
  }

  @keys [:nextDepartures, :trafficInfoEvents]
  @enforce_keys @keys
  defstruct @keys

  def new(args) do
    struct(__MODULE__, %{
      nextDepartures: Enum.map(args.nextDepartures, &Tbm.Departure.new/1),
      trafficInfoEvents: Enum.map(args.trafficInfoEvents, &Tbm.TrafficInfoEvent.new/1),
    })
  end
end
