import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

// Connects to data-controller="pie-chart"
export default class extends Controller {
  static values = {
    data: Array,
    total: String,
    label: String,
  };

  #d3SvgMemo = null;
  #d3GroupMemo = null;
  #d3ContentMemo = null;
  #d3ViewboxWidth = 200;
  #d3ViewboxHeight = 200;

  connect() {
    this.#draw();
    document.addEventListener("turbo:load", this.#redraw);
  }

  disconnect() {
    this.#teardown();
    document.removeEventListener("turbo:load", this.#redraw);
  }

  #redraw = () => {
    this.#teardown();
    this.#draw();
  };

  #teardown() {
    this.#d3SvgMemo = null;
    this.#d3GroupMemo = null;
    this.#d3ContentMemo = null;
    this.#d3Container.selectAll("*").remove();
  }

  #draw() {
    this.#d3Container.attr("class", "relative");
    this.#d3Content.html(this.#contentSummaryTemplate());

    const pie = d3
      .pie()
      .value((d) => d.percent_of_total)
      .padAngle(0.06);

    const arc = d3
      .arc()
      .innerRadius(this.#radius - 8)
      .outerRadius(this.#radius)
      .cornerRadius(2);

    const arcs = this.#d3Group
      .selectAll("arc")
      .data(pie(this.dataValue))
      .enter()
      .append("g")
      .attr("class", "arc");

    const paths = arcs
      .append("path")
      .attr("class", (d) => d.data.fill_color)
      .attr("d", arc);

    paths
      .on("mouseover", (event) => {
        this.#d3Svg.selectAll(".arc path").attr("class", "fill-gray-200");
        d3.select(event.target).attr("class", (d) => d.data.fill_color);
        this.#d3ContentMemo.html(
          this.#contentDetailTemplate(d3.select(event.target).datum().data),
        );
      })
      .on("mouseout", () => {
        this.#d3Svg
          .selectAll(".arc path")
          .attr("class", (d) => d.data.fill_color);
        this.#d3ContentMemo.html(this.#contentSummaryTemplate());
      });
  }

  #contentSummaryTemplate() {
    return `<span class="text-xl text-primary font-medium">${this.totalValue}</span> <span class="text-xs">${this.labelValue}</span>`;
  }

  #contentDetailTemplate(datum) {
    return `
      <span class="text-xl text-primary font-medium">${datum.formatted_value}</span>
      <div class="flex flex-row text-xs gap-2 items-center">
      <div class="w-[10px] h-[10px] rounded-full ${datum.bg_color}"></div>
        <span>${datum.label}</span>
        <span>${datum.percent_of_total}%</span>
      </div>
    `;
  }

  get #radius() {
    return Math.min(this.#d3ViewboxWidth, this.#d3ViewboxHeight) / 2;
  }

  get #d3Container() {
    return d3.select(this.element);
  }

  get #d3Svg() {
    if (!this.#d3SvgMemo) {
      this.#d3SvgMemo = this.#createMainSvg();
    }
    return this.#d3SvgMemo;
  }

  get #d3Group() {
    if (!this.#d3GroupMemo) {
      this.#d3GroupMemo = this.#createMainGroup();
    }

    return this.#d3GroupMemo;
  }

  get #d3Content() {
    if (!this.#d3ContentMemo) {
      this.#d3ContentMemo = this.#createContent();
    }
    return this.#d3ContentMemo;
  }

  #createMainSvg() {
    return this.#d3Container
      .append("svg")
      .attr("width", "100%")
      .attr("class", "relative aspect-1")
      .attr("viewBox", [0, 0, this.#d3ViewboxWidth, this.#d3ViewboxHeight]);
  }

  #createMainGroup() {
    return this.#d3Svg
      .append("g")
      .attr(
        "transform",
        `translate(${this.#d3ViewboxWidth / 2},${this.#d3ViewboxHeight / 2})`,
      );
  }

  #createContent() {
    this.#d3ContentMemo = this.#d3Container
      .append("div")
      .attr(
        "class",
        "absolute inset-0 w-full text-center flex flex-col items-center justify-center",
      );
    return this.#d3ContentMemo;
  }
}
