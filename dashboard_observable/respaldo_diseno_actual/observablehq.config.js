// See https://observablehq.com/framework/config for documentation.
export default {
  title: "Demografía Colombia",
  theme: "light",
  pages: [
    {name: "Inicio", path: "/"},
    {
      name: "Análisis",
      pages: [
        {name: "Fecundidad", path: "/fecundidad"},
        {name: "Escenarios", path: "/escenarios"},
        {name: "Incertidumbre", path: "/incertidumbre"},
        {name: "Sensibilidad", path: "/sensibilidad"}
      ]
    },
    {
      name: "Territorio",
      pages: [
        {name: "Explorador geográfico", path: "/explorador-geografico"}
      ]
    }
  ],
  head: '<link rel="icon" href="observable.png" type="image/png" sizes="32x32"><link rel="stylesheet" href="style.css">',
  globalStylesheets: [],
  root: "src"
};
