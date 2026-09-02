(() => {
  const isLocal = window.location.hostname === "127.0.0.1" || window.location.hostname === "localhost";
  if (!isLocal) return;

  const localProductBase = "http://127.0.0.1:8765";
  const localLinseyBase = "http://127.0.0.1:8767";
  document.querySelectorAll("[data-product-link]").forEach((link) => {
    link.href = `${localProductBase}/`;
  });
  document.querySelectorAll("[data-linsey-link]").forEach((link) => {
    link.href = `${localLinseyBase}/`;
  });
  document.querySelectorAll("[data-local-only]").forEach((element) => {
    element.hidden = false;
  });
})();
