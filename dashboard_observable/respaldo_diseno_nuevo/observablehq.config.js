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
    <span>Demografía Colombia</span>
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
  title: "Demografía Colombia",
  theme: "light",
  sidebar: false,
  toc: false,
  pager: false,
  header: cabecera,
  footer: "Fuentes: DANE (proyecciones de población 2018–2070, Estadísticas Vitales 2018–2025). Demografía Colombia · Proyecto de Estadística.",
  pages: [
    {name: "Inicio", path: "/"},
    {name: "Fecundidad", path: "/fecundidad"},
    {name: "Escenarios", path: "/escenarios"},
    {name: "Incertidumbre", path: "/incertidumbre"},
    {name: "Sensibilidad", path: "/sensibilidad"},
    {name: "Explorador geográfico", path: "/explorador-geografico"}
  ],
  head: `<link rel="icon" href="observable.png" type="image/png" sizes="32x32">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Newsreader:opsz,wght@6..72,500;6..72,600&display=swap">
<link rel="stylesheet" href="style.css">
${scriptNav}`,
  globalStylesheets: [],
  root: "src"
};
