import {readFile} from "node:fs/promises";
import path from "node:path";

// Contorno del archipiélago de San Andrés (datos_limpios/mapa_san_andres.geojson).
// d3/Plot exigen anillos exteriores en sentido horario; GeoJSON estándar los trae antihorarios, así que se invierten.
const filePath = path.resolve(process.cwd(), "..", "datos_limpios", "mapa_san_andres.geojson");

const areaFirmada = (anillo) => anillo.reduce((s, [x1, y1], i) => {
  const [x2, y2] = anillo[(i + 1) % anillo.length];
  return s + (x2 - x1) * (y2 + y1);
}, 0); // > 0: horario

const orientar = (poligono) => poligono.map((anillo, i) => {
  const horario = areaFirmada(anillo) > 0;
  return (i === 0) === horario ? anillo : [...anillo].reverse();
});

try {
  const geo = JSON.parse(await readFile(filePath, "utf8"));
  for (const f of geo.features) {
    const g = f.geometry;
    if (g.type === "Polygon") g.coordinates = orientar(g.coordinates);
    else if (g.type === "MultiPolygon") g.coordinates = g.coordinates.map(orientar);
  }
  process.stdout.write(JSON.stringify(geo));
} catch (error) {
  process.stderr.write(`No se pudo leer datos_limpios/mapa_san_andres.geojson (${filePath}): ${error.message}\n`);
  process.exitCode = 1;
}
