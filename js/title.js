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
    titleTagNames.some(tagName => {
      const titleTag = e.currentSlide.querySelector(tagName);
      if (titleTag === null) {
        return false;
      }
      doc.title = `${originalTitle} - ${e.indexh + 1}.${e.indexv + 1} ${titleTag.textContent}`;
      return true;
    });
  }

  Reveal.on('ready', onSlideOpened);
  Reveal.on('slidechanged', onSlideOpened);
})((this || 0).self || global);
