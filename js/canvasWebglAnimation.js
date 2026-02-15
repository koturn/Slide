;(function(global) {
  'use strict';

  /**
   * Cache of window.document.
   * @type {Document}
   */
  const doc = global.document;
  /**
   * Class definition of Animator.
   * @type {Function}
   */
  const Animator = global.Animator.noConflict();
  /**
   * Class definition of GlslQuadRenderer.
   * @type {Function}
   */
  const GlslQuadRenderer = global.GlslQuadRenderer.noConflict();
  /**
   * Class definition of Animator.
   * @type {Animator}
   */
  const animator = new Animator();
  /**
   * Cache dictionary of GlslQuadRenderer.
   * @type {Object}
   */
  const rendererCache = {};

  /**
   * Send GET request to specified URL.
   * @param {string} url - Target function.
   * @return Promise object of XMLHttpRequest.
   */
  const requestText = typeof global.fetch !== 'undefined' ? async function requestText(url) {
    const response = await global.fetch(url);
    return await response.text();
  } : function requestText(url) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('GET', url);
      xhr.addEventListener('load', e => {
        if (e.target.status === 200) {
          resolve(xhr.responseText);
        } else {
          reject(xhr.responseText);
        }
      });
      xhr.send();
    });
  }

  /**
   * Callback function for slidechanged of reveal.js.
   *
   * Fetch fragment shader source and compile it.
   * After compilation succeeds, start animation.
   *
   * @param {Event} e - Slide event.
   */
  async function onSlideOpenedAsync(e) {
    e.currentSlide.querySelectorAll('canvas').forEach(async canvas => {
      if (canvas === null || typeof canvas.id === 'undefined') {
        return;
      }
      let renderer = rendererCache[canvas.id];
      if (!renderer) {
        const fragmentUrl = canvas.getAttribute('data-fragment-url') + '?t=' + performance.now();
        const fsText = await requestText(fragmentUrl);

        renderer = new GlslQuadRenderer(canvas);
        renderer.build(fsText);
        rendererCache[canvas.id] = renderer;
      }

      renderer.setUniforms(0, 0, 0, canvas.width, canvas.height);
      animator.start(function(now, t, st) {
        const time = animator.totalElapsedTime * 0.001;
        const w = canvas.width;
        const h = canvas.height;
        renderer.setUniforms(time, 0, 0, w, h);
        renderer.render(w, h);
      });
    });
  }

  Reveal.on('slidechanged', e => {
    animator.stop();
    onSlideOpenedAsync(e);
  });

  Reveal.on('ready', onSlideOpenedAsync);
})((this || 0).self || global);
