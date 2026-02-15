;(function(global) {
  'use strict';

  /**
   * Send GET request to specified URL.
   * @param {string} url - Target function.
   * @return Promise object of XMLHttpRequest.
   */
  const sendHeadRequest = typeof global.fetch !== 'undefined' ? function sendHeadRequest(url) {
    return global.fetch(url, { method: 'HEAD' });
  } : function sendHeadRequest(url) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('HEAD', url);
      xhr.addEventListener('load', e => {
        if (e.target.status === 200) {
          resolve(xhr);
        } else {
          reject(xhr);
        }
      });
      xhr.send();
    });
  }

  /**
   * Send theme CSS.
   * @param {string} name - Theme name.
   */
  async function setThemeAsync(name) {
    const url = '../reveal.js/dist/theme/' + name + '.css';
    try {
      // Try to get content to know the content exists or not.
      const response = await sendHeadRequest(url);
      if (response.status === 200) {
        document.getElementById('theme').setAttribute('href', url);
      }
    } catch (e) {
      console.error(e);
      console.error('Theme css not found: ' + url);
    }
  }

  /**
   * Send syntax highlight CSS.
   * @param {string} name - Highlight name.
   */
  async function setHighlightAsync(name) {
    const url = '../reveal.js/plugin/highlight/' + name + '.css';
    try {
      // Try to get content to know the content exists or not.
      const response = await sendHeadRequest(url);
      if (response.status === 200) {
        document.getElementById('highlight').setAttribute('href', url);
      }
    } catch (e) {
      console.error(e);
      console.error('Highlight css not found: ' + url);
    }
  }

  global.setThemeAsync = setThemeAsync;
  global.setHighlightAsync = setHighlightAsync;

  const searchParams = new URLSearchParams(global.location.search);

  const themeName = searchParams.get('theme');
  if (themeName !== null) {
    setThemeAsync(themeName);
  }

  const highlightName = searchParams.get('highlight');
  if (highlightName !== null) {
    setHighlightAsync(highlightName);
  }
})((this || 0).self || global);
