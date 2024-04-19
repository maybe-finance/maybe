import { Controller } from "@hotwired/stimulus"
import tailwindColors from "@maybe/tailwindcolors"
import * as d3 from "d3"

const CHARTABLE_TYPES = [ "scalar", "currency" ]

export default class extends Controller {
  static values = { series: Object, chartedType: String }

  #_dataPoints = []
  #_d3Svg = null
  #_d3InitialContainerWidth = 0
  #_d3InitialContainerHeight = 0

  connect() {
    this.#install()
    document.addEventListener("turbo:load", this.#reinstall)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.#reinstall)
  }

  #reinstall = () => {
    this.#teardown()
    this.#install()
  }

  #teardown() {
    this.#_d3Svg = null
    this.#_dataPoints = []
    this.#d3Container.selectAll("*").remove()
  }

  #install() {
    this.#normalizeDataPoints()
    this.#d3InitialContainerWidth = this.#d3Container.node().clientWidth
    this.#d3InitialContainerHeight = this.#d3Container.node().clientHeight
    this.#draw()
  }

  #normalizeDataPoints() {
    this.#dataPoints = (this.seriesValue.values || []).map((d) => ({
      ...d,
      date: new Date(d.date),
      value: d.value.amount ? +d.value.amount : +d.value,
      currency: d.value.currency || "USD",
    }))
  }

  #draw() {
    if (this.#dataPoints.length < 2) {
      this.#drawEmpty()
    } else if (this.#chartedType === "currency") {
      this.#drawCurrency()
    } else {
      this.#drawLine()
    }
  }

  #drawEmpty() {
    this.#d3Svg.selectAll(".tick").remove()
    this.#d3Svg.selectAll(".domain").remove()

    this.#d3Svg
      .append("line")
      .attr("x1", this.#d3InitialContainerWidth / 2)
      .attr("y1", 0)
      .attr("x2", this.#d3InitialContainerWidth / 2)
      .attr("y2", this.d3InitialContainerHeight)
      .attr("stroke", tailwindColors.gray[300])
      .attr("stroke-dasharray", "4, 4")

    this.#d3Svg
      .append("circle")
      .attr("cx", this.#d3InitialContainerWidth / 2)
      .attr("cy", this.d3InitialContainerHeight / 2)
      .attr("r", 4)
      .style("fill", tailwindColors.gray[400])
  }

  #drawCurrency() {
    const g = this.#d3Svg
      .append("g")
      .attr("transform", `translate(${this.#margin.left},${this.#margin.top})`)

    // X-Axis labels
    g.append("g")
      .attr("transform", `translate(0,${this.#d3ContainerHeight})`)
      .call(
        d3
          .axisBottom(this.#d3XScale)
          .tickValues([ this.#dataPoints[0].date, this.#dataPoints[this.#dataPoints.length - 1].date ])
          .tickSize(0)
          .tickFormat(d3.timeFormat("%b %Y"))
      )
      .select(".domain")
      .remove()

    g.selectAll(".tick text")
      .style("fill", tailwindColors.gray[500])
      .style("font-size", "12px")
      .style("font-weight", "500")
      .attr("text-anchor", "middle")
      .attr("dx", (_d, i) => {
        // We know we only have 2 values
        return i === 0 ? "5em" : "-5em"
      })
      .attr("dy", "0em")

    g.append("path")
      .datum(this.#dataPoints)
      .attr("fill", "none")
      .attr("stroke", tailwindColors.green[500])
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", 1.5)
      .attr("class", "line-chart-path")
      .attr("d", this.#d3Line)

    const tooltip = d3
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

    // Helper to find the closest data point to the mouse
    const bisectDate = d3.bisector(function (d) {
      return d.date
    }).left

    // Create an invisible rectangle that captures mouse events (regular SVG elements don't capture mouse events by default)
    g.append("rect")
      .attr("width", this.#d3ContainerWidth)
      .attr("height", this.#d3ContainerHeight)
      .attr("fill", "none")
      .attr("pointer-events", "all")
      // When user hovers over the chart, show the tooltip and a circle at the closest data point
      .on("mousemove", (event) => {
        tooltip.style("opacity", 1)

        const tooltipWidth = 250 // Estimate or dynamically calculate the tooltip width
        const pageWidth = document.body.clientWidth
        const tooltipX = event.pageX + 10
        const overflowX = tooltipX + tooltipWidth - pageWidth

        const [xPos] = d3.pointer(event)

        const x0 = bisectDate(this.#dataPoints, this.#d3XScale.invert(xPos), 1)
        const d0 = this.#dataPoints[x0 - 1]
        const d1 = this.#dataPoints[x0]
        const d = xPos - this.#d3XScale(d0.date) > this.#d3XScale(d1.date) - xPos ? d1 : d0

        // Adjust tooltip position based on overflow
        const adjustedX =
          overflowX > 0 ? event.pageX - overflowX - 20 : tooltipX

        g.selectAll(".data-point-circle").remove() // Remove existing circles to ensure only one is shown at a time
        g.append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this.#d3XScale(d.date))
          .attr("cy", this.#d3YScale(d.value))
          .attr("r", 8)
          .attr("fill", tailwindColors.green[500])
          .attr("fill-opacity", "0.1")
          .attr("pointer-events", "none")

        g.append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", this.#d3XScale(d.date))
          .attr("cy", this.#d3YScale(d.value))
          .attr("r", 3)
          .attr("fill", tailwindColors.green[500])
          .attr("pointer-events", "none")

        tooltip
          .html(
            `<div style="margin-bottom: 4px; color: ${tailwindColors.gray[500]};">
              ${d3.timeFormat("%b %d, %Y")(d.date)}
            </div>
            <div style="display: flex; align-items: center; gap: 8px;">
              <svg width="10" height="10">
                <circle cx="5" cy="5" r="4" stroke="${this.#currencyColor(d)}" fill="transparent" stroke-width="1"></circle>
              </svg>
              ${this.#currencyValue(d)} <span style="color: ${this.#currencyColor(d)};">${this.#currencyChange(d)} (${d.trend.percent}%)</span>
            </div>`
          )
          .style("left", adjustedX + "px")
          .style("top", event.pageY - 10 + "px")

        g.selectAll(".guideline").remove() // Remove existing line to ensure only one is shown at a time
        g.append("line")
          .attr("class", "guideline")
          .attr("x1", this.#d3XScale(d.date))
          .attr("y1", 0)
          .attr("x2", this.#d3XScale(d.date))
          .attr("y2", this.#d3ContainerHeight)
          .attr("stroke", tailwindColors.gray[300])
          .attr("stroke-dasharray", "4, 4")
      })
      .on("mouseout", () => {
        g.selectAll(".guideline").remove()
        g.selectAll(".data-point-circle").remove()
        tooltip.style("opacity", 0)
      })
  }

  #currencyColor(data) {
    return {
      up: tailwindColors.success,
      down: tailwindColors.error,
      flat: tailwindColors.gray[500],
    }[data.trend.direction]
  }

  #currencyValue(data) {
    return Intl.NumberFormat(undefined, {
      style: "currency",
      currency: data.currency || "USD",
    }).format(data.value)
  }

  #currencyChange(data) {
    return Intl.NumberFormat(undefined, {
      style: "currency",
      currency: data.currency || "USD",
      signDisplay: "always",
    }).format(data.trend.value.amount)
  }

  #drawLine() {
    this.#d3Svg
      .append("path")
      .datum(this.#dataPoints)
      .attr("fill", "none")
      .attr("stroke", this.#trendColor)
      .attr("stroke-width", 2)
      .attr("d", this.#d3Line)
  }

  #createD3Svg() {
    return this.#d3Container
      .append("svg")
      .attr("width", this.#d3InitialContainerWidth)
      .attr("height", this.#d3InitialContainerHeight)
      .attr("viewBox", [ 0, 0, this.#d3InitialContainerWidth, this.#d3InitialContainerHeight ])
  }

  get #margin() {
    if (this.#chartedType === "currency") {
      return { top: 20, right: 1, bottom: 30, left: 1 }
    } else {
      return { top: 0, right: 0, bottom: 0, left: 0 }
    }
  }

  get #dataPoints() {
    return this.#_dataPoints
  }

  set #dataPoints(dataPoints) {
    this.#_dataPoints = dataPoints
  }

  get #chartedType() {
    if (CHARTABLE_TYPES.includes(this.chartedTypeValue)) {
      return this.chartedTypeValue
    } else {
      return "scalar"
    }
  }

  get #d3Svg() {
    if (this.#_d3Svg) {
      return this.#_d3Svg
    } else {
      return this.#_d3Svg = this.#createD3Svg()
    }
  }

  get #d3InitialContainerWidth() {
    return this.#_d3InitialContainerWidth
  }

  set #d3InitialContainerWidth(value) {
    this.#_d3InitialContainerWidth = value
  }

  get #d3InitialContainerHeight() {
    return this.#_d3InitialContainerHeight
  }

  set #d3InitialContainerHeight(value) {
    this.#_d3InitialContainerHeight = value
  }

  get #d3ContainerWidth() {
    return this.#d3InitialContainerWidth - this.#margin.left - this.#margin.right
  }

  get #d3ContainerHeight() {
    return this.#_d3InitialContainerHeight - this.#margin.top - this.#margin.bottom
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
    return this.seriesValue.trend.direction
  }

  get #favorableDirection() {
    return this.seriesValue.trend.favorableDirection
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
      .domain(d3.extent(this.#dataPoints, d => d.date))
  }

  get #d3YScale() {
    let percentPadding

    if (this.#chartedType === "currency") {
      percentPadding = 0.15
    } else {
      percentPadding = 0.05
    }

    const dataMin = d3.min(this.#dataPoints, d => d.value)
    const dataMax = d3.max(this.#dataPoints, d => d.value)
    const padding = (dataMax - dataMin) * percentPadding

    return d3
      .scaleLinear()
      .rangeRound([ this.#d3ContainerHeight, 0 ])
      .domain([ dataMin - padding, dataMax + padding ])
  }
}
