;(function(global) {
  'use strict';

  const doc = global.document;
  const titleTagNames = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
  const originalTitle = doc.title;

  /**
   * Callback function for slidechanged and ready of reveal.js.
   * @param {Event} e - Slide event.
   */
  function onSlideOpened(e) {
    for (let tagName of titleTagNames) {
      const titleTag = e.currentSlide.querySelector(tagName);
      if (titleTag !== null) {
        doc.title = `${originalTitle} - ${e.indexh + 1}.${e.indexv + 1} ${titleTag.textContent}`;
        break;
      }
    }
  }

  Reveal.on('ready', onSlideOpened);
  Reveal.on('slidechanged', onSlideOpened);
})((this || 0).self || global);
