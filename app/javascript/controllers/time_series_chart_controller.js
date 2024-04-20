import { Controller } from "@hotwired/stimulus"
import tailwindColors from "@maybe/tailwindcolors"
import * as d3 from "d3"

export default class extends Controller {
  static values = {
    data: Object,
    useLabels: Boolean,
    useTooltip: Boolean,
    strokeWidth: { type: Number, default: 2 }
  }

  #d3SvgMemo = null
  #d3GroupMemo = null
  #d3Tooltip = null
  #d3InitialContainerWidth = 0
  #d3InitialContainerHeight = 0
  #normalDataPoints = []

  connect() {
    this.#install()
    document.addEventListener("turbo:load", this.#reinstall)
  }

  disconnect() {
    this.#teardown()
    document.removeEventListener("turbo:load", this.#reinstall)
  }


  #reinstall = () => {
    this.#teardown()
    this.#install()
  }

  #teardown() {
    this.#d3SvgMemo = null
    this.#d3GroupMemo = null
    this.#d3Tooltip = null
    this.#normalDataPoints = []

    this.#d3Container.selectAll("*").remove()
  }

  #install() {
    this.#normalizeDataPoints()
    this.#rememberInitialContainerSize()
    this.#draw()
  }


  #normalizeDataPoints() {
    this.#normalDataPoints = (this.dataValue.values || []).map((d) => ({
      ...d,
      date: new Date(d.date),
      value: d.value.amount ? +d.value.amount : +d.value,
      currency: d.value.currency
    }))
  }


  #rememberInitialContainerSize() {
    this.#d3InitialContainerWidth = this.#d3Container.node().clientWidth
    this.#d3InitialContainerHeight = this.#d3Container.node().clientHeight
  }


  #draw() {
    if (this.#normalDataPoints.length < 2) {
      this.#drawEmpty()
    } else {
      this.#drawChart()
    }
  }


  #drawEmpty() {
    this.#d3Svg.selectAll(".tick").remove()
    this.#d3Svg.selectAll(".domain").remove()

    this.#drawDashedLineEmptyState()
    this.#drawCenteredCircleEmptyState()
  }

  #drawDashedLineEmptyState() {
    this.#d3Svg
      .append("line")
      .attr("x1", this.#d3InitialContainerWidth / 2)
      .attr("y1", 0)
      .attr("x2", this.#d3InitialContainerWidth / 2)
      .attr("y2", this.#d3InitialContainerHeight)
      .attr("stroke", tailwindColors.gray[300])
      .attr("stroke-dasharray", "4, 4")
  }

  #drawCenteredCircleEmptyState() {
    this.#d3Svg
      .append("circle")
      .attr("cx", this.#d3InitialContainerWidth / 2)
      .attr("cy", this.#d3InitialContainerHeight / 2)
      .attr("r", 4)
      .style("fill", tailwindColors.gray[400])
  }


  #drawChart() {
    this.#drawTrendline()

    if (this.useLabelsValue) {
      this.#drawXAxisLabels()
    }

    if (this.useTooltipValue) {
      this.#drawTooltip()
      this.#trackMouseForShowingTooltip()
    }
  }

  #drawXAxisLabels() {
    // Add ticks
    this.#d3Group
      .append("g")
      .attr("transform", `translate(0,${this.#d3ContainerHeight})`)
      .call(
        d3
          .axisBottom(this.#d3XScale)
          .tickValues([ this.#normalDataPoints[0].date, this.#normalDataPoints[this.#normalDataPoints.length - 1].date ])
          .tickSize(0)
          .tickFormat(d3.timeFormat("%b %Y"))
      )
      .select(".domain")
      .remove()

    // Style ticks
    this.#d3Group.selectAll(".tick text")
      .style("fill", tailwindColors.gray[500])
      .style("font-size", "12px")
      .style("font-weight", "500")
      .attr("text-anchor", "middle")
      .attr("dx", (_d, i) => {
        // We know we only have 2 values
        return i === 0 ? "5em" : "-5em"
      })
      .attr("dy", "0em")
  }

  #drawTrendline() {
    this.#d3Group
      .append("path")
      .datum(this.#normalDataPoints)
      .attr("fill", "none")
      .attr("stroke", this.#trendColor)
      .attr("d", this.#d3Line)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", this.strokeWidthValue)
  }

  #drawTooltip() {
    this.#d3Tooltip = d3
      .select("#lineChart")
      .append("div")
      .style("position", "absolute")
      .style("padding", "8px")
      .style("font", "14px Inter, sans-serif")
      .style("background", tailwindColors.white)
      .style("border", `1px solid ${tailwindColors["alpha-black"][100]}`)
      .style("border-radius", "10px")
      .style("pointer-events", "none")
      .style("opacity", 0) // Starts as hidden
  }

  #trackMouseForShowingTooltip() {
    const bisectDate = d3.bisector(d => d.date).left

    this.#d3Group.append("rect")
      .attr("width", this.#d3ContainerWidth)
      .attr("height", this.#d3ContainerHeight)
      .attr("fill", "none")
      .attr("pointer-events", "all")
      .on("mousemove", (event) => {
        const estimatedTooltipWidth = 250
        const pageWidth = document.body.clientWidth
        const tooltipX = event.pageX + 10
        const overflowX = tooltipX + estimatedTooltipWidth - pageWidth
        const adjustedX = overflowX > 0 ? event.pageX - overflowX - 20 : tooltipX

        const [xPos] = d3.pointer(event)
        const x0 = bisectDate(this.#normalDataPoints, this.#d3XScale.invert(xPos), 1)
        const d0 = this.#normalDataPoints[x0 - 1]
        const d1 = this.#normalDataPoints[x0]
        const d = xPos - this.#d3XScale(d0.date) > this.#d3XScale(d1.date) - xPos ? d1 : d0

        // Reset
        this.#d3Group.selectAll(".data-point-circle").remove()
        this.#d3Group.selectAll(".guideline").remove()

        // Big circle
        this.#d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this.#d3XScale(d.date))
          .attr("cy", this.#d3YScale(d.value))
          .attr("r", 8)
          .attr("fill", this.#trendColor)
          .attr("fill-opacity", "0.1")
          .attr("pointer-events", "none")

        // Small circle
        this.#d3Group
          .append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this.#d3XScale(d.date))
          .attr("cy", this.#d3YScale(d.value))
          .attr("r", 3)
          .attr("fill", this.#trendColor)
          .attr("pointer-events", "none")

        // Guideline
        this.#d3Group
          .append("line")
          .attr("class", "guideline")
          .attr("x1", this.#d3XScale(d.date))
          .attr("y1", 0)
          .attr("x2", this.#d3XScale(d.date))
          .attr("y2", this.#d3ContainerHeight)
          .attr("stroke", tailwindColors.gray[300])
          .attr("stroke-dasharray", "4, 4")

        // Render tooltip
        this.#d3Tooltip
          .html(this.#tooltipTemplate(d))
          .style("opacity", 1)
          .style("left", adjustedX + "px")
          .style("top", event.pageY - 10 + "px")
      })
      .on("mouseout", () => {
        this.#d3Group.selectAll(".guideline").remove()
        this.#d3Group.selectAll(".data-point-circle").remove()
        this.#d3Tooltip.style("opacity", 0)
      })
  }


  #tooltipTemplate(data) {
    if (data.currency) {
      return(`
        <div style="margin-bottom: 4px; color: ${tailwindColors.gray[500]};">
          ${d3.timeFormat("%b %d, %Y")(data.date)}
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <svg width="10" height="10">
            <circle cx="5" cy="5" r="4" stroke="${this.#dataTrendColor(data)}" fill="transparent" stroke-width="1"></circle>
          </svg>
          ${this.#currencyValue(data)} <span style="color: ${this.#dataTrendColor(data)};">${this.#currencyChange(data)} (${data.trend.percent}%)</span>
        </div>
      `)
    } else {
      return(`
        <div style="margin-bottom: 4px; color: ${tailwindColors.gray[500]};">
          ${d3.timeFormat("%b %d, %Y")(data.date)}
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <svg width="10" height="10">
            <circle cx="5" cy="5" r="4" stroke="${this.#dataTrendColor(data)}" fill="transparent" stroke-width="1"></circle>
          </svg>
          ${data.value} <span style="color: ${this.#dataTrendColor(data)};">${this.#decimalChange(data)} (${data.trend.percent}%)</span>
        </div>
      `)
    }
  }

  #dataTrendColor(data) {
    return {
      up: tailwindColors.success,
      down: tailwindColors.error,
      flat: tailwindColors.gray[500],
    }[data.trend.direction]
  }

  #currencyValue(data) {
    return Intl.NumberFormat(undefined, {
      style: "currency",
      currency: data.currency,
    }).format(data.value)
  }

  #currencyChange(data) {
    return Intl.NumberFormat(undefined, {
      style: "currency",
      currency: data.currency,
      signDisplay: "always",
    }).format(data.trend.value.amount)
  }

  #decimalChange(data) {
    return Intl.NumberFormat(undefined, {
      style: "decimal",
      signDisplay: "always",
    }).format(data.trend.value)
  }


  #createMainSvg() {
    return this.#d3Container
      .append("svg")
      .attr("width", this.#d3InitialContainerWidth)
      .attr("height", this.#d3InitialContainerHeight)
      .attr("viewBox", [ 0, 0, this.#d3InitialContainerWidth, this.#d3InitialContainerHeight ])
  }

  #createMainGroup() {
    return this.#d3Svg
      .append("g")
      .attr("transform", `translate(${this.#margin.left},${this.#margin.top})`)
  }


  get #d3Svg() {
    if (this.#d3SvgMemo) {
      return this.#d3SvgMemo
    } else {
      return this.#d3SvgMemo = this.#createMainSvg()
    }
  }

  get #d3Group() {
    if (this.#d3GroupMemo) {
      return this.#d3GroupMemo
    } else {
      return this.#d3GroupMemo = this.#createMainGroup()
    }
  }

  get #margin() {
    if (this.useLabelsValue) {
      return { top: 20, right: 1, bottom: 30, left: 1 }
    } else {
      return { top: 0, right: 0, bottom: 0, left: 0 }
    }
  }

  get #d3ContainerWidth() {
    return this.#d3InitialContainerWidth - this.#margin.left - this.#margin.right
  }

  get #d3ContainerHeight() {
    return this.#d3InitialContainerHeight - this.#margin.top - this.#margin.bottom
  }

  get #d3Container() {
    return d3.select(this.element)
  }

  get #trendColor() {
    if (this.#trendDirection === "flat") {
      return tailwindColors.gray[500]
    } else if (this.#trendDirection === this.#favorableDirection) {
      return tailwindColors.green[500]
    } else {
      return tailwindColors.error
    }
  }

  get #trendDirection() {
    return this.dataValue.trend.direction
  }

  get #favorableDirection() {
    return this.dataValue.trend.favorableDirection
  }

  get #d3Line() {
    return d3
      .line()
      .x(d => this.#d3XScale(d.date))
      .y(d => this.#d3YScale(d.value))
  }

  get #d3XScale() {
    return d3
      .scaleTime()
      .rangeRound([ 0, this.#d3ContainerWidth ])
      .domain(d3.extent(this.#normalDataPoints, d => d.date))
  }

  get #d3YScale() {
    const reductionPercent = this.useLabelsValue ? 0.15 : 0.05
    const dataMin = d3.min(this.#normalDataPoints, d => d.value)
    const dataMax = d3.max(this.#normalDataPoints, d => d.value)
    const padding = (dataMax - dataMin) * reductionPercent

    return d3
      .scaleLinear()
      .rangeRound([ this.#d3ContainerHeight, 0 ])
      .domain([ dataMin - padding, dataMax + padding ])
  }
}
