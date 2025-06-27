import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

const parseLocalDate = d3.timeParse("%Y-%m-%d");

export default class extends Controller {
  static values = {
    data: Object,
    strokeWidth: { type: Number, default: 2 },
    useLabels: { type: Boolean, default: true },
    useTooltip: { type: Boolean, default: true },
  };

  _d3SvgMemo = null;
  _d3GroupMemo = null;
  _d3Tooltip = null;
  _d3InitialContainerWidth = 0;
  _d3InitialContainerHeight = 0;
  _normalDataPoints = [];
  _resizeObserver = null;

  connect() {
    this._install();
    document.addEventListener("turbo:load", this._reinstall);
    this._setupResizeObserver();
  }

  disconnect() {
    this._teardown();
    document.removeEventListener("turbo:load", this._reinstall);
    this._resizeObserver?.disconnect();
  }

  _reinstall = () => {
    this._teardown();
    this._install();
  };

  _teardown() {
    this._d3SvgMemo = null;
    this._d3GroupMemo = null;
    this._d3Tooltip = null;
    this._normalDataPoints = [];

    this._d3Container.selectAll("*").remove();
  }

  _install() {
    this._normalizeDataPoints();
    this._rememberInitialContainerSize();
    this._draw();
  }

  _normalizeDataPoints() {
    this._normalDataPoints = (this.dataValue.values || []).map((d) => ({
      date: parseLocalDate(d.date),
      date_formatted: d.date_formatted,
      value: d.value,
      trend: d.trend,
    }));
  }

  _rememberInitialContainerSize() {
    this._d3InitialContainerWidth = this._d3Container.node().clientWidth;
    this._d3InitialContainerHeight = this._d3Container.node().clientHeight;
  }

  _draw() {
    if (this._normalDataPoints.length < 2) {
      this._drawEmpty();
    } else {
      this._drawChart();
    }
  }

  _drawEmpty() {
    this._d3Svg.selectAll(".tick").remove();
    this._d3Svg.selectAll(".domain").remove();

    this._drawDashedLineEmptyState();
    this._drawCenteredCircleEmptyState();
  }

  _drawDashedLineEmptyState() {
    this._d3Svg
      .append("line")
      .attr("x1", this._d3InitialContainerWidth / 2)
      .attr("y1", 0)
      .attr("x2", this._d3InitialContainerWidth / 2)
      .attr("y2", this._d3InitialContainerHeight)
      .attr("stroke", "var(--color-gray-300)")
      .attr("stroke-dasharray", "4, 4");
  }

  _drawCenteredCircleEmptyState() {
    this._d3Svg
      .append("circle")
      .attr("cx", this._d3InitialContainerWidth / 2)
      .attr("cy", this._d3InitialContainerHeight / 2)
      .attr("r", 4)
      .attr("class", "fg-subdued")
      .style("fill", "currentColor");
  }

  _drawChart() {
    this._drawTrendline();

    if (this.useLabelsValue) {
      this._drawXAxisLabels();
      this._drawGradientBelowTrendline();
    }

    if (this.useTooltipValue) {
      this._drawTooltip();
      this._trackMouseForShowingTooltip();
    }
  }

  _drawTrendline() {
    this._installTrendlineSplit();

    this._d3Group
      .append("path")
      .datum(this._normalDataPoints)
      .attr("fill", "none")
      .attr("stroke", `url(#${this.element.id}-split-gradient)`)
      .attr("d", this._d3Line)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", this.strokeWidthValue);
  }

  _installTrendlineSplit() {
    const gradient = this._d3Svg
      .append("defs")
      .append("linearGradient")
      .attr("id", `${this.element.id}-split-gradient`)
      .attr("gradientUnits", "userSpaceOnUse")
      .attr("x1", this._d3XScale.range()[0])
      .attr("x2", this._d3XScale.range()[1]);

    // First stop - solid trend color
    gradient
      .append("stop")
      .attr("class", "start-color")
      .attr("offset", "0%")
      .attr("stop-color", this.dataValue.trend.color);

    // Second stop - trend color right before split
    gradient
      .append("stop")
      .attr("class", "split-before")
      .attr("offset", "100%")
      .attr("stop-color", this.dataValue.trend.color);

    // Third stop - gray color right after split
    gradient
      .append("stop")
      .attr("class", "split-after")
      .attr("offset", "100%")
      .attr("stop-color", "var(--color-gray-400)");

    // Fourth stop - solid gray to end
    gradient
      .append("stop")
      .attr("class", "end-color")
      .attr("offset", "100%")
      .attr("stop-color", "var(--color-gray-400)");
  }

  _setTrendlineSplitAt(percent) {
    const position = percent * 100;

    // Update both stops at the split point
    this._d3Svg
      .select(`#${this.element.id}-split-gradient`)
      .select(".split-before")
      .attr("offset", `${position}%`);

    this._d3Svg
      .select(`#${this.element.id}-split-gradient`)
      .select(".split-after")
      .attr("offset", `${position}%`);

    this._d3Svg
      .select(`#${this.element.id}-trendline-gradient-rect`)
      .attr("width", this._d3ContainerWidth * percent);
  }

  _drawXAxisLabels() {
    // Add ticks
    this._d3Group
      .append("g")
      .attr("transform", `translate(0,${this._d3ContainerHeight})`)
      .call(
        d3
          .axisBottom(this._d3XScale)
          .tickValues([
            this._normalDataPoints[0].date,
            this._normalDataPoints[this._normalDataPoints.length - 1].date,
          ])
          .tickSize(0)
          .tickFormat(d3.timeFormat("%b %d, %Y")),
      )
      .select(".domain")
      .remove();

    // Style ticks
    this._d3Group
      .selectAll(".tick text")
      .attr("class", "fg-gray")
      .style("font-size", "12px")
      .style("font-weight", "500")
      .attr("text-anchor", "middle")
      .attr("dx", (_d, i) => {
        // We know we only have 2 values
        return i === 0 ? "5em" : "-5em";
      })
      .attr("dy", "0em");
  }

  _drawGradientBelowTrendline() {
    // Define gradient
    const gradient = this._d3Group
      .append("defs")
      .append("linearGradient")
      .attr("id", `${this.element.id}-trendline-gradient`)
      .attr("gradientUnits", "userSpaceOnUse")
      .attr("x1", 0)
      .attr("x2", 0)
      .attr(
        "y1",
        this._d3YScale(d3.max(this._normalDataPoints, this._getDatumValue)),
      )
      .attr("y2", this._d3ContainerHeight);

    gradient
      .append("stop")
      .attr("offset", 0)
      .attr("stop-color", this._trendColor)
      .attr("stop-opacity", 0.06);

    gradient
      .append("stop")
      .attr("offset", 0.5)
      .attr("stop-color", this._trendColor)
      .attr("stop-opacity", 0);

    // Clip path makes gradient start at the trendline
    this._d3Group
      .append("clipPath")
      .attr("id", `${this.element.id}-clip-below-trendline`)
      .append("path")
      .datum(this._normalDataPoints)
      .attr(
        "d",
        d3
          .area()
          .x((d) => this._d3XScale(d.date))
          .y0(this._d3ContainerHeight)
          .y1((d) => this._d3YScale(this._getDatumValue(d))),
      );

    // Apply the gradient + clip path
    this._d3Group
      .append("rect")
      .attr("id", `${this.element.id}-trendline-gradient-rect`)
      .attr("width", this._d3ContainerWidth)
      .attr("height", this._d3ContainerHeight)
      .attr("clip-path", `url(#${this.element.id}-clip-below-trendline)`)
      .style("fill", `url(#${this.element.id}-trendline-gradient)`);
  }

  _drawTooltip() {
    this._d3Tooltip = d3
      .select(`#${this.element.id}`)
      .append("div")
      .attr(
        "class",
        "bg-container text-sm font-sans absolute p-2 border border-secondary rounded-lg pointer-events-none opacity-0",
      );
  }

  _trackMouseForShowingTooltip() {
    const bisectDate = d3.bisector((d) => d.date).left;

    this._d3Group
      .append("rect")
      .attr("class", "bg-container")
      .attr("width", this._d3ContainerWidth)
      .attr("height", this._d3ContainerHeight)
      .attr("fill", "none")
      .attr("pointer-events", "all")
      .on("mousemove", (event) => {
        const estimatedTooltipWidth = 250;
        const pageWidth = document.body.clientWidth;
        const tooltipX = event.pageX + 10;
        const overflowX = tooltipX + estimatedTooltipWidth - pageWidth;
        const adjustedX =
          overflowX > 0 ? event.pageX - overflowX - 20 : tooltipX;

        const [xPos] = d3.pointer(event);
        const x0 = bisectDate(
          this._normalDataPoints,
          this._d3XScale.invert(xPos),
          1,
        );
        const d0 = this._normalDataPoints[x0 - 1];
        const d1 = this._normalDataPoints[x0];
        const d =
          xPos - this._d3XScale(d0.date) > this._d3XScale(d1.date) - xPos
            ? d1
            : d0;
        const xPercent = this._d3XScale(d.date) / this._d3ContainerWidth;

        this._setTrendlineSplitAt(xPercent);

        // Reset
        this._d3Group.selectAll(".data-point-circle").remove();
        this._d3Group.selectAll(".guideline").remove();

        // Guideline
        this._d3Group
          .append("line")
          .attr("class", "guideline fg-subdued")
          .attr("x1", this._d3XScale(d.date))
          .attr("y1", 0)
          .attr("x2", this._d3XScale(d.date))
          .attr("y2", this._d3ContainerHeight)
          .attr("stroke", "currentColor")
          .attr("stroke-dasharray", "4, 4");

        // Big circle
        this._d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this._d3XScale(d.date))
          .attr("cy", this._d3YScale(this._getDatumValue(d)))
          .attr("r", 10)
          .attr("fill", this._trendColor)
          .attr("fill-opacity", "0.1")
          .attr("pointer-events", "none");

        // Small circle
        this._d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this._d3XScale(d.date))
          .attr("cy", this._d3YScale(this._getDatumValue(d)))
          .attr("r", 5)
          .attr("fill", this._trendColor)
          .attr("pointer-events", "none");

        // Render tooltip
        this._d3Tooltip
          .html(this._tooltipTemplate(d))
          .style("opacity", 1)
          .style("z-index", 999)
          .style("left", `${adjustedX}px`)
          .style("top", `${event.pageY - 10}px`);
      })
      .on("mouseout", (event) => {
        const hoveringOnGuideline =
          event.toElement?.classList.contains("guideline");

        if (!hoveringOnGuideline) {
          this._d3Group.selectAll(".guideline").remove();
          this._d3Group.selectAll(".data-point-circle").remove();
          this._d3Tooltip.style("opacity", 0);
          this._setTrendlineSplitAt(1);
        }
      });
  }

  _tooltipTemplate(datum) {
    return `
      <div style="margin-bottom: 4px; color: var(--color-gray-500);">
        ${datum.date_formatted}
      </div>
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2 text-primary">
          <div class="flex items-center justify-center h-4 w-4">
            ${this._getTrendIcon(datum)}
          </div>
          ${this._extractFormattedValue(datum.trend.current)}
        </div>

        ${
          datum.trend.value === 0
            ? `<span class="w-20"></span>`
            : `
          <span style="color: ${datum.trend.color};">
            ${this._extractFormattedValue(datum.trend.value)} (${datum.trend.percent_formatted})
          </span>
        `
        }
      </div>
    `;
  }

  _getTrendIcon(datum) {
    const isIncrease =
      Number(datum.trend.previous.amount) < Number(datum.trend.current.amount);
    const isDecrease =
      Number(datum.trend.previous.amount) > Number(datum.trend.current.amount);

    if (isIncrease) {
      return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="${datum.trend.color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-arrow-up-right-icon lucide-arrow-up-right"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>`;
    }

    if (isDecrease) {
      return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="${datum.trend.color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-arrow-down-right-icon lucide-arrow-down-right"><path d="m7 7 10 10"/><path d="M17 7v10H7"/></svg>`;
    }

    return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="${datum.trend.color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-minus-icon lucide-minus"><path d="M5 12h14"/></svg>`;
  }

  _getDatumValue = (datum) => {
    return this._extractNumericValue(datum.value);
  };

  _extractNumericValue = (numeric) => {
    if (typeof numeric === "object" && "amount" in numeric) {
      return Number(numeric.amount);
    }
    return Number(numeric);
  };

  _extractFormattedValue = (numeric) => {
    if (typeof numeric === "object" && "formatted" in numeric) {
      return numeric.formatted;
    }
    return numeric;
  };

  _createMainSvg() {
    return this._d3Container
      .append("svg")
      .attr("width", this._d3InitialContainerWidth)
      .attr("height", this._d3InitialContainerHeight)
      .attr("viewBox", [
        0,
        0,
        this._d3InitialContainerWidth,
        this._d3InitialContainerHeight,
      ]);
  }

  _createMainGroup() {
    return this._d3Svg
      .append("g")
      .attr("transform", `translate(${this._margin.left},${this._margin.top})`);
  }

  get _d3Svg() {
    if (!this._d3SvgMemo) {
      this._d3SvgMemo = this._createMainSvg();
    }
    return this._d3SvgMemo;
  }

  get _d3Group() {
    if (!this._d3GroupMemo) {
      this._d3GroupMemo = this._createMainGroup();
    }
    return this._d3GroupMemo;
  }

  get _margin() {
    if (this.useLabelsValue) {
      return { top: 20, right: 0, bottom: 10, left: 0 };
    }
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }

  get _d3ContainerWidth() {
    return (
      this._d3InitialContainerWidth - this._margin.left - this._margin.right
    );
  }

  get _d3ContainerHeight() {
    return (
      this._d3InitialContainerHeight - this._margin.top - this._margin.bottom
    );
  }

  get _d3Container() {
    return d3.select(this.element);
  }

  get _trendColor() {
    return this.dataValue.trend.color;
  }

  get _d3Line() {
    return d3
      .line()
      .x((d) => this._d3XScale(d.date))
      .y((d) => this._d3YScale(this._getDatumValue(d)));
  }

  get _d3XScale() {
    return d3
      .scaleTime()
      .rangeRound([0, this._d3ContainerWidth])
      .domain(d3.extent(this._normalDataPoints, (d) => d.date));
  }

  get _d3YScale() {
    const dataMin = d3.min(this._normalDataPoints, this._getDatumValue);
    const dataMax = d3.max(this._normalDataPoints, this._getDatumValue);

    // Handle edge case where all values are the same
    if (dataMin === dataMax) {
      const padding = dataMax === 0 ? 100 : Math.abs(dataMax) * 0.5;
      return d3
        .scaleLinear()
        .rangeRound([this._d3ContainerHeight, 0])
        .domain([dataMin - padding, dataMax + padding]);
    }

    const dataRange = dataMax - dataMin;
    const avgValue = (dataMax + dataMin) / 2;

    // Calculate relative change as a percentage
    const relativeChange = avgValue !== 0 ? dataRange / Math.abs(avgValue) : 1;

    // Dynamic baseline calculation
    let yMin;
    let yMax;

    // For small relative changes (< 10%), use a tighter scale
    if (relativeChange < 0.1 && dataMin > 0) {
      // Start axis at a percentage below the minimum, not at 0
      const baselinePadding = dataRange * 2; // Show 2x the data range below min
      yMin = Math.max(0, dataMin - baselinePadding);
      yMax = dataMax + dataRange * 0.5; // Add 50% padding above
    } else {
      // For larger changes or when data crosses zero, use more context
      // Always include 0 when data is negative or close to 0
      if (dataMin < 0 || (dataMin >= 0 && dataMin < avgValue * 0.1)) {
        yMin = Math.min(0, dataMin * 1.1);
      } else {
        // Otherwise use dynamic baseline
        yMin = dataMin - dataRange * 0.3;
      }
      yMax = dataMax + dataRange * 0.1;
    }

    // Adjust padding for labels if needed
    if (this.useLabelsValue) {
      const extraPadding = (yMax - yMin) * 0.1;
      yMin -= extraPadding;
      yMax += extraPadding;
    }

    return d3
      .scaleLinear()
      .rangeRound([this._d3ContainerHeight, 0])
      .domain([yMin, yMax]);
  }

  _setupResizeObserver() {
    this._resizeObserver = new ResizeObserver(() => {
      this._reinstall();
    });
    this._resizeObserver.observe(this.element);
  }
}
