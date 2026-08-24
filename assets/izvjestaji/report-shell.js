(() => {
  "use strict";

  const bar = document.querySelector(".reading-progress__bar");
  if (!bar) return;

  let framePending = false;
  const update = () => {
    framePending = false;
    const root = document.documentElement;
    const distance = Math.max(1, root.scrollHeight - window.innerHeight);
    const progress = Math.min(1, Math.max(0, window.scrollY / distance));
    bar.style.transform = `scaleX(${progress})`;
  };

  const requestUpdate = () => {
    if (framePending) return;
    framePending = true;
    window.requestAnimationFrame(update);
  };

  window.addEventListener("scroll", requestUpdate, { passive: true });
  window.addEventListener("resize", requestUpdate, { passive: true });
  window.addEventListener("pageshow", requestUpdate);
  update();
})();
