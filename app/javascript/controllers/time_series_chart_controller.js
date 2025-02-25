import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

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
      date: new Date(`${d.date}T00:00:00Z`),
      date_formatted: d.date_formatted,
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
      .style("fill", "var(--color-gray-400)");
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

    gradient
      .append("stop")
      .attr("class", "start-color")
      .attr("offset", "0%")
      .attr("stop-color", this.dataValue.trend.color);

    gradient
      .append("stop")
      .attr("class", "middle-color")
      .attr("offset", "100%")
      .attr("stop-color", this.dataValue.trend.color);

    gradient
      .append("stop")
      .attr("class", "end-color")
      .attr("offset", "100%")
      .attr("stop-color", "var(--color-gray-300)");
  }

  _setTrendlineSplitAt(percent) {
    this._d3Svg
      .select(`#${this.element.id}-split-gradient`)
      .select(".middle-color")
      .attr("offset", `${percent * 100}%`);

    this._d3Svg
      .select(`#${this.element.id}-split-gradient`)
      .select(".end-color")
      .attr("offset", `${percent * 100}%`);

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
          .tickFormat(d3.utcFormat("%b %d, %Y")),
      )
      .select(".domain")
      .remove();

    // Style ticks
    this._d3Group
      .selectAll(".tick text")
      .style("fill", "var(--color-gray-500)")
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
      .style("position", "absolute")
      .style("padding", "8px")
      .style("font", "14px Inter, sans-serif")
      .style("background", "var(--color-white)")
      .style("border", "1px solid var(--color-alpha-black-100)")
      .style("border-radius", "10px")
      .style("pointer-events", "none")
      .style("opacity", 0); // Starts as hidden
  }

  _trackMouseForShowingTooltip() {
    const bisectDate = d3.bisector((d) => d.date).left;

    this._d3Group
      .append("rect")
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
          .attr("class", "guideline")
          .attr("x1", this._d3XScale(d.date))
          .attr("y1", 0)
          .attr("x2", this._d3XScale(d.date))
          .attr("y2", this._d3ContainerHeight)
          .attr("stroke", "var(--color-gray-300)")
          .attr("stroke-dasharray", "4, 4");

        // Big circle
        this._d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this._d3XScale(d.date))
          .attr("cy", this._d3YScale(this._getDatumValue(d)))
          .attr("r", 8)
          .attr("fill", this._trendColor)
          .attr("fill-opacity", "0.1")
          .attr("pointer-events", "none");

        // Small circle
        this._d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this._d3XScale(d.date))
          .attr("cy", this._d3YScale(this._getDatumValue(d)))
          .attr("r", 3)
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

      <div style="display: flex; align-items: center; gap: 16px;">
        <div style="display: flex; align-items: center; gap: 8px;">
          <svg width="10" height="10">
            <circle
              cx="5"
              cy="5"
              r="4"
              stroke="${datum.trend.color}"
              fill="transparent"
              stroke-width="1"></circle>
          </svg>

          ${this._extractFormattedValue(datum.trend.current)}
        </div>

        ${
          datum.trend.value === 0
            ? `<span style="width: 80px;"></span>`
            : `
          <span style="color: ${datum.trend.color};">
            ${this._extractFormattedValue(datum.trend.value)} (${datum.trend.percent_formatted})
          </span>
        `
        }
      </div>
    `;
  }

  _getDatumValue = (datum) => {
    return this._extractNumericValue(datum.trend.current);
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
    const reductionPercent = this.useLabelsValue ? 0.3 : 0.05;
    const dataMin = d3.min(this._normalDataPoints, this._getDatumValue);
    const dataMax = d3.max(this._normalDataPoints, this._getDatumValue);
    const padding = (dataMax - dataMin) * reductionPercent;

    return d3
      .scaleLinear()
      .rangeRound([this._d3ContainerHeight, 0])
      .domain([dataMin - padding, dataMax + padding]);
  }

  _setupResizeObserver() {
    this._resizeObserver = new ResizeObserver(() => {
      this._reinstall();
    });
    this._resizeObserver.observe(this.element);
  }
}
