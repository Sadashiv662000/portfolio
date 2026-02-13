document.addEventListener('DOMContentLoaded', function () {
  const btn = document.querySelector('.nav-toggle');
  const nav = document.querySelector('.nav');
  if (btn) {
    btn.addEventListener('click', () => {
      if (!nav) return;
      const shown = nav.style.display === 'block';
      nav.style.display = shown ? 'none' : 'block';
    });
  }

  // Reveal hero content on load with a small upward motion
  const revealTargets = Array.from(document.querySelectorAll('.hero-title, .hero-sub, .hero-cta'));
  revealTargets.forEach((el, i) => {
    el.classList.add('will-reveal');
    setTimeout(() => el.classList.add('is-visible'), 150 + i * 120);
  });
});
