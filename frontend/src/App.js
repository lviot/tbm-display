import React, { useEffect, useRef, useState } from "react";

// ---------------------------------------------------------------------
// CONFIG API
// ---------------------------------------------------------------------

const API_BASE_URL = "http://192.168.1.44:8080/api/v1";

// GET /stop_areas?filter=<query>
async function fetchStopAreas(query) {
  const url = `${API_BASE_URL}/stop_areas?filter=${encodeURIComponent(query)}`;

  const res = await fetch(url, {
    headers: { Accept: "application/json" },
  });

  if (!res.ok) {
    throw new Error(`Erreur lors du chargement des arrêts (${res.status})`);
  }

  const data = await res.json();

  // mapping adapté à ta réponse:
  // id, name, lines[].code, lines[].style.color
  return data.map((item) => ({
    id: item.id,
    name: item.name,
    lines: (item.lines || []).map((l) => ({
      id: l.id,
      code: l.code,
      color: l.style?.color,
    })),
  }));
}

// GET /stop_area/{stopAreaId}/directions
async function fetchDirections(stopAreaId) {
  const res = await fetch(
    `${API_BASE_URL}/stop_area/${encodeURIComponent(stopAreaId)}/directions`,
    { headers: { Accept: "application/json" } }
  );

  if (!res.ok) {
    throw new Error(
      `Erreur lors du chargement des directions (${res.status})`
    );
  }

  const data = await res.json();

  return data.map((item) => ({
    id: item.route.id,
    name: item.route.name,
    line: {
      id: item.line.id,
      code: item.line.code,
      color: item.line.style?.color,
    },
  }));
}

// POST /stop_area/{id}/route/{routeId}/set
async function setConfiguration(stopAreaId, routeId) {
  const res = await fetch(
    `${API_BASE_URL}/stop_area/${encodeURIComponent(
      stopAreaId
    )}/route/${encodeURIComponent(routeId)}/set`,
    { method: "POST" }
  );

  if (!res.ok) {
    throw new Error(
      `Erreur lors de l’envoi de la configuration (${res.status})`
    );
  }
}

// ---------------------------------------------------------------------
// UI components
// ---------------------------------------------------------------------

const LineBadge = ({ line }) => {
  const bg = line.color || "#fb923c";
  return (
    <span
      className="inline-flex h-7 min-w-[2.5rem] items-center justify-center rounded-full px-2 text-xs font-semibold text-white shadow-sm"
      style={{ background: bg }}
    >
      {line.code}
    </span>
  );
};

function FancySelect({
                       label,
                       placeholder,
                       disabled,
                       options,
                       value,
                       onChange,
                       renderOption,
                       getKey,
                       // nouvelles props pour la recherche
                       searchable = false,
                       searchValue = "",
                       onSearchChange,
                       searchPlaceholder = "Rechercher...",
                       noOptionsLabel = "Aucune option",
                     }) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);

  // Ferme au clic extérieur
  useEffect(() => {
    if (!open) return;
    const handleClick = (e) => {
      if (!containerRef.current) return;
      if (!containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  const handleSelect = (opt) => {
    onChange(opt);
    setOpen(false);
  };

  return (
    <div
      ref={containerRef}
      className={`space-y-1 ${disabled ? "opacity-50" : ""}`}
    >
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium text-slate-800">{label}</span>
        {value && (
          <button
            type="button"
            className="text-xs text-slate-500 hover:text-slate-700"
            onClick={() => handleSelect(null)}
          >
            Réinitialiser
          </button>
        )}
      </div>

      <div className="relative">
        <button
          type="button"
          disabled={disabled}
          onClick={() => !disabled && setOpen((prev) => !prev)}
          className="mt-1 flex w-full items-center justify-between rounded-2xl border border-white/60 bg-white/80 px-3 py-3 text-left text-sm text-slate-800 shadow-[0_10px_40px_rgba(15,23,42,0.12)] outline-none backdrop-blur-md transition focus:border-sky-400 focus:ring-2 focus:ring-sky-300/60 disabled:cursor-not-allowed"
        >
          <span className="flex min-w-0 items-center gap-2">
            {value ? (
              <span className="inline-flex min-w-0 flex-1 items-center gap-2 truncate">
                {renderOption(value)}
              </span>
            ) : (
              <span className="truncate text-slate-400">{placeholder}</span>
            )}
          </span>
          <span className="ml-2 flex items-center text-slate-400">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className={`h-4 w-4 transition-transform ${
                open ? "rotate-180" : ""
              }`}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M19 9l-7 7-7-7"
              />
            </svg>
          </span>
        </button>

        {open && !disabled && (
          <div className="absolute z-20 mt-2 max-h-64 w-full overflow-y-auto rounded-2xl border border-slate-100 bg-white/95 p-1 text-sm shadow-[0_18px_45px_rgba(15,23,42,0.22)]">
            {searchable && (
              <div className="px-2 pb-1 pt-2 border-b border-slate-100">
                <input
                  type="text"
                  className="w-full rounded-xl border border-slate-200 px-2 py-1 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-sky-300 focus:border-sky-300"
                  placeholder={searchPlaceholder}
                  value={searchValue}
                  onChange={(e) =>
                    onSearchChange && onSearchChange(e.target.value)
                  }
                  autoFocus
                />
              </div>
            )}

            {options.length === 0 ? (
              <div className="px-3 py-2 text-xs text-slate-400">
                {noOptionsLabel}
              </div>
            ) : (
              options.map((opt) => {
                const k = getKey(opt);
                const isActive = value && getKey(value) === k;
                return (
                  <button
                    key={k}
                    type="button"
                    onClick={() => handleSelect(opt)}
                    className={`flex w-full items-center gap-2 rounded-2xl px-3 py-2 text-left text-xs sm:text-sm transition hover:bg-sky-50 ${
                      isActive ? "bg-sky-100/80 text-sky-800" : "text-slate-800"
                    }`}
                  >
                    {renderOption(opt)}
                  </button>
                );
              })
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------
// App principale
// ---------------------------------------------------------------------

export default function App() {
  const [stopAreas, setStopAreas] = useState([]);
  const [directions, setDirections] = useState([]);
  const [selectedStopArea, setSelectedStopArea] = useState(null);
  const [selectedDirection, setSelectedDirection] = useState(null);

  const [loadingStops, setLoadingStops] = useState(false);
  const [loadingDirections, setLoadingDirections] = useState(false);
  const [savingConfig, setSavingConfig] = useState(false);

  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  // 🔍 texte saisi dans le champ de recherche d'arrêt
  const [stopSearch, setStopSearch] = useState("");
  const [stopSearchDebounced, setStopSearchDebounced] = useState("");

  // debounce de la recherche stop_area
  useEffect(() => {
    const id = setTimeout(() => {
      setStopSearchDebounced(stopSearch.trim());
    }, 300);
    return () => clearTimeout(id);
  }, [stopSearch]);

  // Charger les stop_areas en fonction du texte tapé
  useEffect(() => {
    // si moins de 2 caractères, on ne cherche pas
    if (!stopSearchDebounced || stopSearchDebounced.length < 2) {
      setStopAreas([]);
      return;
    }

    const load = async () => {
      try {
        setLoadingStops(true);
        setError(null);
        setSuccess(null);
        const stops = await fetchStopAreas(stopSearchDebounced);
        setStopAreas(stops);
      } catch (e) {
        setError(e.message || "Erreur lors du chargement des arrêts");
      } finally {
        setLoadingStops(false);
      }
    };

    load();
  }, [stopSearchDebounced]);

  // Charger les directions quand un stop_area est sélectionné
  useEffect(() => {
    if (!selectedStopArea) {
      setDirections([]);
      setSelectedDirection(null);
      return;
    }

    const load = async () => {
      try {
        setLoadingDirections(true);
        setError(null);
        setSuccess(null);
        const dirs = await fetchDirections(selectedStopArea.id);
        setDirections(dirs);
      } catch (e) {
        setError(e.message || "Erreur lors du chargement des directions");
      } finally {
        setLoadingDirections(false);
      }
    };

    load();
  }, [selectedStopArea]);

  const handleSave = async () => {
    if (!selectedStopArea || !selectedDirection) return;
    try {
      setSavingConfig(true);
      setError(null);
      setSuccess(null);
      await setConfiguration(selectedStopArea.id, selectedDirection.id);
      setSuccess("Configuration envoyée à la matrice LED ✅");
    } catch (e) {
      setError(
        e.message || "Erreur lors de l’envoi de la configuration à la matrice"
      );
    } finally {
      setSavingConfig(false);
    }
  };

  const stopNoOptionsLabel =
    !stopSearchDebounced || stopSearchDebounced.length < 2
      ? "Tape au moins 2 lettres pour chercher un arrêt"
      : "Aucun arrêt trouvé pour cette recherche";

  return (
    <div className="min-h-screen w-full bg-gradient-to-br from-sky-100 via-rose-50 to-amber-100 px-4 py-6 text-slate-900 sm:flex sm:items-center sm:justify-center">
      <div className="mx-auto w-full max-w-md">
        <div className="relative rounded-3xl bg-white/70 p-[1px] shadow-[0_20px_60px_rgba(15,23,42,0.18)] backdrop-blur-xl">
          <div className="relative flex h-full w-full flex-col gap-6 rounded-3xl bg-gradient-to-b from-white/90 to-sky-50/80 px-5 py-6 sm:px-7 sm:py-7">
            {/* Gradient blob */}
            <div className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-gradient-to-br from-sky-300/40 via-indigo-300/20 to-rose-200/40 blur-3xl" />

            <header className="relative flex flex-col gap-2">
              <div className="inline-flex max-w-fit items-center gap-2 rounded-full bg-sky-100/80 px-3 py-1 text-[11px] font-medium text-sky-700 shadow-sm">
                <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-white/80 text-[11px] font-bold text-sky-500 shadow">
                  TBM
                </span>
                <span>Onboarding matrice LED</span>
              </div>
              <h1 className="text-xl font-semibold tracking-tight text-slate-900 sm:text-2xl">
                Configure ton affichage temps réel
              </h1>
              <p className="text-xs text-slate-600 sm:text-sm">
                Commence par rechercher un arrêt, puis choisis une direction.
                Ces choix piloteront ta matrice LED.
              </p>
            </header>

            <main className="relative flex flex-col gap-4">
              {error && (
                <div className="rounded-2xl border border-rose-200 bg-rose-50/80 px-3 py-2 text-xs text-rose-700">
                  {error}
                </div>
              )}
              {success && (
                <div className="rounded-2xl border border-emerald-200 bg-emerald-50/80 px-3 py-2 text-xs text-emerald-700">
                  {success}
                </div>
              )}

              {/* STOP AREA SEARCH + SELECT */}
              <FancySelect
                label="Arrêt (stop_area)"
                placeholder={
                  loadingStops
                    ? "Chargement..."
                    : "Clique puis tape pour chercher un arrêt"
                }
                disabled={false}
                options={stopAreas}
                value={selectedStopArea}
                onChange={(value) => {
                  setSelectedStopArea(value);
                  setSelectedDirection(null);
                  setSuccess(null);
                  if (value) {
                    setStopSearch(value.name);
                    setStopSearchDebounced(value.name);
                  }
                }}
                getKey={(s) => s.id}
                renderOption={(s) => (
                  <span className="inline-flex w-full items-center justify-between gap-2">
                    <span className="inline-flex max-w-[70%] flex-1 flex-wrap items-center gap-2 truncate">
                      <span className="inline-flex flex-wrap items-center gap-1">
                        {s.lines.slice(0, 4).map((line) => (
                          <LineBadge key={line.id} line={line} />
                        ))}
                        {s.lines.length > 4 && (
                          <span className="text-[10px] text-slate-500">
                            +{s.lines.length - 4}
                          </span>
                        )}
                      </span>
                      <span className="truncate font-medium">{s.name}</span>
                    </span>
                  </span>
                )}
                searchable={true}
                searchValue={stopSearch}
                onSearchChange={(v) => {
                  setStopSearch(v);
                  // si l'utilisateur efface, on reset la sélection
                  if (!v) {
                    setStopAreas([]);
                    setSelectedStopArea(null);
                    setSelectedDirection(null);
                  }
                }}
                searchPlaceholder="Ex : Parc de Mussonville"
                noOptionsLabel={stopNoOptionsLabel}
              />

              {/* DIRECTIONS */}
              <FancySelect
                label="Direction"
                placeholder={
                  !selectedStopArea
                    ? "Choisis d'abord un arrêt"
                    : loadingDirections
                      ? "Chargement des directions..."
                      : directions.length === 0
                        ? "Aucune direction disponible"
                        : "Sélectionne une direction"
                }
                disabled={
                  !selectedStopArea ||
                  loadingDirections ||
                  directions.length === 0
                }
                options={directions}
                value={selectedDirection}
                onChange={(value) => {
                  setSelectedDirection(value);
                  setSuccess(null);
                }}
                getKey={(d) => d.id}
                renderOption={(d) => (
                  <span className="inline-flex w-full items-center justify-between gap-2">
                    <span className="inline-flex max-w-[80%] flex-1 items-center gap-2 truncate">
                      <LineBadge line={d.line} />
                      <span className="truncate font-medium">{d.name}</span>
                    </span>
                  </span>
                )}
              />
            </main>

            <footer className="relative mt-2 flex flex-col gap-3 rounded-2xl bg-white/70 px-4 py-3 text-xs text-slate-600 shadow-inner">
              <div className="flex items-center justify-between gap-3">
                <div className="flex flex-col">
                  <span className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">
                    Sélection actuelle
                  </span>
                  {selectedStopArea ? (
                    <div className="mt-1 flex flex-col gap-1">
                      <span className="text-xs font-medium text-slate-800">
                        {selectedStopArea.name}
                      </span>
                      {selectedDirection ? (
                        <span className="inline-flex items-center gap-2 text-[11px] text-slate-600">
                          <LineBadge line={selectedDirection.line} />
                          <span>{selectedDirection.name}</span>
                        </span>
                      ) : (
                        <span className="text-[11px] text-slate-500">
                          Choisis une direction pour finaliser.
                        </span>
                      )}
                    </div>
                  ) : (
                    <span className="mt-1 text-[11px] text-slate-500">
                      Aucun arrêt sélectionné pour l'instant.
                    </span>
                  )}
                </div>
                <button
                  type="button"
                  className="inline-flex shrink-0 items-center justify-center rounded-2xl bg-gradient-to-r from-sky-400 via-sky-500 to-indigo-400 px-4 py-2 text-xs font-semibold text-white shadow-md shadow-sky-500/40 transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50"
                  disabled={
                    !selectedStopArea || !selectedDirection || savingConfig
                  }
                  onClick={handleSave}
                >
                  {savingConfig ? "Envoi..." : "Lancer l'affichage"}
                </button>
              </div>
              <p className="text-[10px] text-slate-400">
                Cette configuration est envoyée à ton service, qui pilote la
                matrice LED en temps réel.
              </p>
            </footer>
          </div>
        </div>
      </div>
    </div>
  );
}
