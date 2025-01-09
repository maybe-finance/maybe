import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

export default class extends Controller {
  static targets = ["chart"];
  static values = {
    segments: Array,
    total: Number,
  };

  connect() {
    const containerRect = this.element.getBoundingClientRect();
    this.size = Math.min(containerRect.width, containerRect.height);
    this.#draw();
  }

  disconnect() {
    if (this.#d3Container) {
      this.#d3Container.selectAll("*").remove();
    }
  }

  #draw() {
    const total = this.segmentsValue.reduce(
      (sum, segment) => sum + segment.value,
      0,
    );

    let dataToRender;

    if (this.totalValue === null || this.segmentsValue.length === 0) {
      dataToRender = [
        {
          fill_color: "fill-gray-100",
          value: 100, // Using arbitrary value since it will fill 100% of the chart
        },
      ];
    } else {
      const isOverdrawn = total > this.totalValue;
      dataToRender = isOverdrawn
        ? this.segmentsValue
        : [
            ...this.segmentsValue,
            ...(this.totalValue - total > 0
              ? [
                  {
                    fill_color: "fill-gray-100",
                    value: this.totalValue - total,
                  },
                ]
              : []),
          ];
    }

    const pie = d3
      .pie()
      .value((d) => d.value)
      .padAngle(0.004 * 2 * Math.PI)
      .sort(null);

    // Define arc
    const mainArc = d3
      .arc()
      .innerRadius(this.size / 2 - 10)
      .outerRadius(this.size / 2)
      .cornerRadius(5);

    const svg = this.#d3Container
      .select("svg")
      .attr("viewBox", `0 0 ${this.size} ${this.size}`)
      .attr("preserveAspectRatio", "xMidYMid meet")
      .attr("width", "100%")
      .attr("height", "100%");

    const group = svg
      .append("g")
      .attr("transform", `translate(${this.size / 2},${this.size / 2})`);

    // Draw main segments
    group
      .selectAll("arc")
      .data(pie(dataToRender))
      .enter()
      .append("g")
      .attr("class", "arc")
      .append("path")
      .attr("class", (d) => d.data.fill_color)
      .attr("d", mainArc);
  }

  get #d3Container() {
    return d3.select(this.element);
  }
}
