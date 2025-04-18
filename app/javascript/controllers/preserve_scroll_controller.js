/* 
  https://dev.to/konnorrogers/maintain-scroll-position-in-turbo-without-data-turbo-permanent-2b1i
  modified to add support for horizontal scrolling
 */
if (!window.scrollPositions) {
  window.scrollPositions = {};
}

function preserveScroll() {
  document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    scrollPositions[element.id] = {
      top: element.scrollTop,
      left: element.scrollLeft
    };
  });
}

function restoreScroll(event) {
  document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    if (scrollPositions[element.id]) {
      element.scrollTop = scrollPositions[element.id].top;
      element.scrollLeft = scrollPositions[element.id].left;
    }
  });

  if (!event.detail.newBody) return;
  // event.detail.newBody is the body element to be swapped in.
  // https://turbo.hotwired.dev/reference/events
  event.detail.newBody.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
    if (scrollPositions[element.id]) {
      element.scrollTop = scrollPositions[element.id].top;
      element.scrollLeft = scrollPositions[element.id].left;
    }
  });
}

window.addEventListener("turbo:before-cache", preserveScroll);
window.addEventListener("turbo:before-render", restoreScroll);
window.addEventListener("turbo:render", restoreScroll);
