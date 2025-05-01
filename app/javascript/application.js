// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};

if (typeof console !== "undefined") {
  console.debug = console.log;
  window.onerror = (msg, url, line) => {
    console.log(`Error: ${msg}\nURL: ${url}\nLine: ${line}`);
    return false;
  };
}
