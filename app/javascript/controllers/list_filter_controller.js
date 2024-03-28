import { Controller } from "@hotwired/stimulus";

// Basic functionality to filter a list based on a provided text attribute.
export default class extends Controller {
  static targets = ["input", "list"];

  filter() {
    const filterValue = this.inputTarget.value.toLowerCase();
    const items = this.listTarget.querySelectorAll(".filterable-item");

    items.forEach((item) => {
      const text = item.getAttribute("data-filter-name").toLowerCase();
      item.style.display = text.includes(filterValue) ? "" : "none";
    });
  }
}
