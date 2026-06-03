import L from 'leaflet';
import { useEffect, useMemo } from 'react';
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet';

export type MapPointKind = 'courier' | 'business' | 'delivery';

export type MapPoint = {
  id: string;
  label: string;
  subtitle?: string;
  lat: number;
  lon: number;
  kind: MapPointKind;
};

function createIcon(kind: MapPointKind) {
  return L.divIcon({
    className: '',
    html: `<span class="map-pin map-pin-${kind}"></span>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  });
}

function FitBounds({ points }: { points: MapPoint[] }) {
  const map = useMap();

  useEffect(() => {
    if (!points.length) return;

    if (points.length === 1) {
      map.setView([points[0].lat, points[0].lon], 15);
      return;
    }

    const bounds = L.latLngBounds(points.map((point) => [point.lat, point.lon]));
    map.fitBounds(bounds, { padding: [44, 44], maxZoom: 16 });
  }, [map, points]);

  return null;
}

export function CourierMap({ points }: { points: MapPoint[] }) {
  const center = points[0] ? [points[0].lat, points[0].lon] : [43.238, 76.945];
  const icons = useMemo(
    () => ({
      courier: createIcon('courier'),
      business: createIcon('business'),
      delivery: createIcon('delivery'),
    }),
    [],
  );

  return (
    <div className="h-[420px] overflow-hidden rounded-lg border border-line bg-white shadow-sm">
      <MapContainer
        center={center as [number, number]}
        zoom={points.length ? 13 : 11}
        className="h-full w-full"
        scrollWheelZoom
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FitBounds points={points} />
        {points.map((point) => (
          <Marker
            key={point.id}
            position={[point.lat, point.lon]}
            icon={icons[point.kind]}
          >
            <Popup>
              <div className="space-y-1">
                <p className="font-semibold">{point.label}</p>
                {point.subtitle ? <p>{point.subtitle}</p> : null}
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
