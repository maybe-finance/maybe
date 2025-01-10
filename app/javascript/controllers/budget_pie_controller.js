import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

export default class extends Controller {
  static values = {
    segments: Array,
    total: Number,
    showOverages: Boolean,
  };

  connect() {
    this.#draw();
  }

  disconnect() {
    d3.select(this.element).selectAll("*").remove();
  }

  #draw() {
    const containerRect = this.element.getBoundingClientRect();
    this.size = Math.min(containerRect.width, containerRect.height);

    const container = d3.select(this.element);
    container.selectAll("svg").remove();

    const svg = container
      .append("svg")
      .attr("viewBox", `0 0 ${this.size} ${this.size}`)
      .attr("preserveAspectRatio", "xMidYMid meet")
      .attr("width", "100%")
      .attr("height", "100%");

    const total = this.segmentsValue.reduce(
      (sum, segment) => sum + Number(segment.value),
      0,
    );

    const overage = Math.max(0, total - this.totalValue);

    let dataToRender;

    if (this.totalValue === null || this.segmentsValue.length === 0) {
      dataToRender = [
        {
          fill_color: "#F0F0F0",
          value: 100,
        },
      ];
    } else if (this.totalValue === 0) {
      if (overage && this.showOveragesValue) {
        dataToRender = [
          {
            fill_color: "#EF4444",
            value: 100,
          },
        ];
      } else {
        dataToRender = [
          {
            fill_color: "#F0F0F0",
            value: 100,
          },
        ];
      }
    } else {
      const isOverdrawn = total > this.totalValue;

      if (isOverdrawn && this.showOveragesValue) {
        dataToRender = [
          { fill_color: "#EF4444", value: overage },
          ...this.segmentsValue,
        ];
      } else {
        dataToRender = [
          ...this.segmentsValue.filter(
            (segment) => Math.abs(Number(segment.value)) > 0,
          ),
          ...(this.totalValue - total > 0
            ? [{ fill_color: "#F0F0F0", value: this.totalValue - total }]
            : []),
        ];
      }
    }

    const pie = d3
      .pie()
      .value((d) => d.value)
      .padAngle(Math.max(0.02, Math.min(0.05, 0.3 / Math.sqrt(this.size))))
      .sort(null);

    const mainArc = d3
      .arc()
      .innerRadius(
        this.size / 2 -
          Math.max(3, Math.min(14, (this.size * 0.5) / Math.sqrt(this.size))),
      )
      .outerRadius(this.size / 2)
      .cornerRadius(5);

    const group = svg
      .append("g")
      .attr("transform", `translate(${this.size / 2},${this.size / 2})`);

    group
      .selectAll("arc")
      .data(pie(dataToRender))
      .enter()
      .append("g")
      .attr("class", "arc")
      .append("path")
      .attr("fill", (d) => d.data.fill_color)
      .attr("d", mainArc);
  }
}
