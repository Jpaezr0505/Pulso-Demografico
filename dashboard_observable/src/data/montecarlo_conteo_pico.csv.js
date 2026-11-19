import {readFile} from "node:fs/promises";
import path from "node:path";

const filePath = path.resolve(process.cwd(), "..", "resultados", "montecarlo_conteo_pico.csv");

try {
  process.stdout.write(await readFile(filePath, "utf8"));
} catch (error) {
  process.stderr.write(`No se pudo leer resultados/montecarlo_conteo_pico.csv (${filePath}): ${error.message}\n`);
  process.exitCode = 1;
}
