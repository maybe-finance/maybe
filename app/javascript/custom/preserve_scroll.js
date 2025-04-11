/**
 * Preserve Scroll Position
 *
 * This module preserves scroll positions (both horizontal and vertical) of elements with
 * the 'data-preserve-scroll' attribute during Turbo navigations.
 *
 * Usage:
 * Add the 'data-preserve-scroll' attribute to any scrollable element whose
 * scroll position you want to preserve across navigations.
 * Each element must have a unique id attribute.
 *
 * Example:
 * <div id="my-scrollable-container" data-preserve-scroll>...</div>
 *
 *
 * NOTE: There is this extensive discussion about scroll perserve with Turbo
 * https://github.com/hotwired/turbo/issues/37
 * we used a modified version from Kronnor Rogers solution
 * https://dev.to/konnorrogers/maintain-scroll-position-in-turbo-without-data-turbo-permanent-2b1i
 */

// Store scroll positions globally
if (!window.scrollPositions) {
  window.scrollPositions = {};
}

/**
 * Preserve scroll positions of elements with data-preserve-scroll attribute
 */
function preserveScroll() {
  document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    if (element.id) {
      window.scrollPositions[element.id] = {
        scrollTop: element.scrollTop,
        scrollLeft: element.scrollLeft
      };
    }
  });
}

/**
 * Restore scroll positions to elements with data-preserve-scroll attribute
 */
function restoreScroll(event) {
  // Restore scroll for current elements
  document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    if (element.id && window.scrollPositions[element.id]) {
      const pos = window.scrollPositions[element.id];
      element.scrollTop = pos.scrollTop || 0;
      element.scrollLeft = pos.scrollLeft || 0;
    }
  });

  // For new body coming in through Turbo navigation
  if (event && event.detail && event.detail.newBody) {
    event.detail.newBody.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
      if (element.id && window.scrollPositions[element.id]) {
        const pos = window.scrollPositions[element.id];
        // Set data attributes so that when elements are rendered, they can restore scroll
        element.dataset.scrollTop = pos.scrollTop || 0;
        element.dataset.scrollLeft = pos.scrollLeft || 0;
      }
    });
  }
}

/**
 * Finish the restoration after render by reading data attributes
 */
function finishRestoreScroll() {
  document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    if (element.dataset.scrollTop) {
      element.scrollTop = parseInt(element.dataset.scrollTop, 10);
      delete element.dataset.scrollTop;
    }
    if (element.dataset.scrollLeft) {
      element.scrollLeft = parseInt(element.dataset.scrollLeft, 10);
      delete element.dataset.scrollLeft;
    }
  });
}

// Register event listeners
window.addEventListener("turbo:before-cache", preserveScroll);
window.addEventListener("turbo:before-render", restoreScroll);
window.addEventListener("turbo:render", finishRestoreScroll);

// Export functions for testing or manual use
export { preserveScroll, restoreScroll, finishRestoreScroll };