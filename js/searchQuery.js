;(function(global) {
  'use strict';

  /**
   * Send GET request to specified URL.
   * @param {string} url - Target function.
   * @return Promise object of XMLHttpRequest.
   */
  function sendGetRequest(url) {
    const p = new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('GET', url);
      xhr.addEventListener('load', e => resolve(xhr));
      xhr.send();
    });
    return p;
  }

  /**
   * Send theme CSS.
   * @param {string} name - Theme name.
   */
  async function setTheme(name) {
    const url = '../reveal.js/dist/theme/' + name + '.css';
    try {
      // Try to get content to know the content exists or not.
      const xhr = await sendGetRequest(url);
      if (xhr.status !== 404) {
        document.getElementById('theme').setAttribute('href', url);
      }
    } catch (e) {
      console.error(e);
    }
  }

  /**
   * Send syntax highlight CSS.
   * @param {string} name - Highlight name.
   */
  async function setHighlight(name) {
    const url = '../reveal.js/plugin/highlight/' + name + '.css';
    try {
      // Try to get content to know the content exists or not.
      const xhr = await sendGetRequest(url);
      if (xhr.status !== 404) {
        document.getElementById('highlight').setAttribute('href', url);
      }
    } catch (e) {
      console.error(e);
    }
  }

  global.setTheme = setTheme;
  global.setHighlight = setHighlight;

  const searchParams = new URLSearchParams(global.location.search);

  const themeName = searchParams.get('theme');
  if (themeName !== null) {
    setTheme(themeName);
  }

  const highlightName = searchParams.get('highlight');
  if (highlightName !== null) {
    setHighlight(highlightName);
  }
})((this || 0).self || global);
