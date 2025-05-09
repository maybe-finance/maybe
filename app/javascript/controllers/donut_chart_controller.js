import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

// Connects to data-controller="donut-chart"
export default class extends Controller {
  static targets = ["chartContainer", "contentContainer", "defaultContent"];
  static values = {
    segments: { type: Array, default: [] },
    unusedSegmentId: { type: String, default: "unused" },
    overageSegmentId: { type: String, default: "overage" },
    segmentHeight: { type: Number, default: 3 },
    segmentOpacity: { type: Number, default: 1 },
  };

  #viewBoxSize = 100;
  #minSegmentAngle = this.segmentHeightValue * 0.01;

  connect() {
    this.#draw();
    document.addEventListener("turbo:load", this.#redraw);
    this.element.addEventListener("mouseleave", this.#clearSegmentHover);
  }

  disconnect() {
    this.#teardown();
    document.removeEventListener("turbo:load", this.#redraw);
    this.element.removeEventListener("mouseleave", this.#clearSegmentHover);
  }

  get #data() {
    const totalPieValue = this.segmentsValue.reduce(
      (acc, s) => acc + Number(s.amount),
      0,
    );

    // Overage is always first segment, unused is always last segment
    return this.segmentsValue
      .filter((s) => s.amount > 0)
      .map((s) => ({
        ...s,
        amount: Math.max(
          Number(s.amount),
          totalPieValue * this.#minSegmentAngle,
        ),
      }))
      .sort((a, b) => {
        if (a.id === this.overageSegmentIdValue) return -1;
        if (b.id === this.overageSegmentIdValue) return 1;
        if (a.id === this.unusedSegmentIdValue) return 1;
        if (b.id === this.unusedSegmentIdValue) return -1;
        return b.amount - a.amount;
      });
  }

  #redraw = () => {
    this.#teardown();
    this.#draw();
  };

  #teardown() {
    d3.select(this.chartContainerTarget).selectAll("*").remove();
  }

  #draw() {
    const svg = d3
      .select(this.chartContainerTarget)
      .append("svg")
      .attr("viewBox", `0 0 ${this.#viewBoxSize} ${this.#viewBoxSize}`) // Square aspect ratio
      .attr("preserveAspectRatio", "xMidYMid meet")
      .attr("class", "w-full h-full");

    const pie = d3
      .pie()
      .sortValues(null) // Preserve order of segments
      .value((d) => d.amount);

    const mainArc = d3
      .arc()
      .innerRadius(this.#viewBoxSize / 2 - this.segmentHeightValue)
      .outerRadius(this.#viewBoxSize / 2)
      .cornerRadius(this.segmentHeightValue)
      .padAngle(this.#minSegmentAngle);

    const segmentArcs = svg
      .append("g")
      .attr(
        "transform",
        `translate(${this.#viewBoxSize / 2}, ${this.#viewBoxSize / 2})`,
      )
      .selectAll("arc")
      .data(pie(this.#data))
      .enter()
      .append("g")
      .attr("class", "arc pointer-events-auto")
      .append("path")
      .attr("data-segment-id", (d) => d.data.id)
      .attr("data-original-color", this.#transformRingColor)
      .attr("fill", this.#transformRingColor)
      .attr("d", mainArc);

    // Ensures that user can click on default content without triggering hover on a segment if that is their intent
    let hoverTimeout = null;

    segmentArcs
      .on("mouseover", (event) => {
        hoverTimeout = setTimeout(() => {
          this.#clearSegmentHover();
          this.#handleSegmentHover(event);
        }, 150);
      })
      .on("mouseleave", () => {
        clearTimeout(hoverTimeout);
      });
  }

  #transformRingColor = ({ data: { id, color } }) => {
    if (id === this.unusedSegmentIdValue || id === this.overageSegmentIdValue) {
      return color;
    }

    const reducedOpacityColor = d3.color(color);
    reducedOpacityColor.opacity = this.segmentOpacityValue;
    return reducedOpacityColor;
  };

  // Highlights segment and shows segment specific content (all other segments are grayed out)
  #handleSegmentHover(event) {
    const segmentId = event.target.dataset.segmentId;
    const template = this.element.querySelector(`#segment_${segmentId}`);
    const unusedSegmentId = this.unusedSegmentIdValue;

    if (!template) return;

    d3.select(this.chartContainerTarget)
      .selectAll("path")
      .attr("fill", function () {
        if (this.dataset.segmentId === segmentId) {
          if (this.dataset.segmentId === unusedSegmentId) {
            return "var(--budget-unused-fill)";
          }

          return this.dataset.originalColor;
        }

        return "var(--budget-unallocated-fill)";
      });

    this.defaultContentTarget.classList.add("hidden");
    template.classList.remove("hidden");
  }

  // Restores original segment colors and hides segment specific content
  #clearSegmentHover = () => {
    this.defaultContentTarget.classList.remove("hidden");

    d3.select(this.chartContainerTarget)
      .selectAll("path")
      .attr("fill", function () {
        return this.dataset.originalColor;
      });

    for (const child of this.contentContainerTarget.children) {
      if (child !== this.defaultContentTarget) {
        child.classList.add("hidden");
      }
    }
  };
}
