// See https://observablehq.com/framework/config for documentation.
const enlaces = [
  ["Inicio", "/"],
  ["Fecundidad", "/fecundidad"],
  ["Escenarios", "/escenarios"],
  ["Incertidumbre", "/incertidumbre"],
  ["Sensibilidad", "/sensibilidad"],
  ["Territorio", "/explorador-geografico"]
];

const cabecera = `
<div class="topbar">
  <a class="brand" href="/">
    <svg class="brand-mark" viewBox="0 0 34 34" role="img" aria-label="Logotipo">
      <rect width="34" height="34" rx="9" fill="#0B7A6E"/>
      <path d="M6 25 C 11 25, 12 9, 17 9 C 22 9, 23 25, 28 25" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round"/>
    </svg>
    <span>Pulso Demográfico</span>
  </a>
  <nav class="topnav" aria-label="Principal">
    ${enlaces.map(([nombre, ruta]) => `<a href="${ruta}">${nombre}</a>`).join("\n    ")}
  </nav>
</div>`;

// Marca la página activa en la barra superior
const scriptNav = `<script>
document.addEventListener("DOMContentLoaded", () => {
  const limpiar = (r) => r.replace(/index\\.html$/, "").replace(/\\.html$/, "").replace(/\\/$/, "") || "/";
  const ruta = limpiar(location.pathname);
  document.querySelectorAll(".topnav a").forEach((a) => {
    if (limpiar(a.pathname) === ruta) a.setAttribute("aria-current", "page");
  });
});
</script>`;

export default {
  title: "Pulso Demográfico",
  theme: "light",
  sidebar: false,
  toc: false,
  pager: false,
  header: cabecera,
  footer: "Fuentes: DANE (proyecciones de población 2018–2070, Estadísticas Vitales 2018–2025). Pulso Demográfico · Proyecto de Estadística.",
  pages: [
    {name: "Inicio", path: "/"},
    {name: "Fecundidad", path: "/fecundidad"},
    {name: "Escenarios", path: "/escenarios"},
    {name: "Incertidumbre", path: "/incertidumbre"},
    {name: "Sensibilidad", path: "/sensibilidad"},
    {name: "Explorador geográfico", path: "/explorador-geografico"}
  ],
  head: `<script>document.documentElement.lang = "es";</script>
<meta name="description" content="Pulso Demográfico: del dato a la decisión. Qué tan probable es el máximo de población que el DANE proyecta para 2043, con escenarios, incertidumbre, sensibilidad y mapa por departamento.">
<script>
// Permite ampliar con los dedos (el tema base bloquea el zoom con maximum-scale=1).
document.querySelector('meta[name="viewport"]')?.setAttribute("content", "width=device-width, initial-scale=1");
</script>
<script>
// Accesibilidad: describe cada gráfico de Plot que no tenga descripción, usando el título de su sección.
new MutationObserver(() => {
  document.querySelectorAll('svg[width="15"][height="15"]:not([aria-hidden])').forEach(svg => svg.setAttribute("aria-hidden", "true"));
  document.querySelectorAll('svg[class*="plot-"]:not([aria-label]):not([aria-hidden])').forEach(svg => {
    if (svg.closest("[aria-label]")) return;
    let el = svg.closest("figure") || svg, t = "";
    while (el && !t) {
      let p = el.previousElementSibling;
      while (p && !t) { const h = p.matches("h2,h3") ? p : p.querySelector("h2,h3"); if (h) t = h.textContent.trim(); p = p.previousElementSibling; }
      el = el.parentElement;
      if (el && el.id === "observablehq-main") break;
    }
    svg.setAttribute("role", "img");
    svg.setAttribute("aria-label", t ? "Gráfico: " + t : "Gráfico");
  });
}).observe(document.documentElement, {childList: true, subtree: true});
</script>
<link rel="icon" href="observable.png" type="image/png" sizes="32x32">
<link rel="stylesheet" href="style.css">
${scriptNav}`,
  globalStylesheets: [],
  root: "src"
};
