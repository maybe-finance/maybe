import { Controller } from "@hotwired/stimulus"
import tailwindColors from "@maybe/tailwindcolors"
import * as d3 from "d3"

export default class extends Controller {
  static values = { series: Object }

  #_dataPoints = []
  #_d3Svg = null

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
    this.#draw()
  }

  #normalizeDataPoints() {
    this.#dataPoints = (this.seriesValue.values || []).map((d) => ({
      date: new Date(d.date),
      value: d.value.amount ? +d.value.amount : +d.value,
    }))
  }

  #draw() {
    if (this.#dataPoints.length < 2) {
      this.#drawEmpty()
    } else {
      this.#drawLine()
    }
  }

  #drawEmpty() {
    this.#d3Svg.selectAll(".tick").remove()
    this.#d3Svg.selectAll(".domain").remove()

    this.#d3Svg
      .append("line")
      .attr("x1", this.#d3Svg.node().clientWidth / 2)
      .attr("y1", 0)
      .attr("x2", this.#d3Svg.node().clientWidth / 2)
      .attr("y2", this.#d3Svg.node().clientHeight)
      .attr("stroke", tailwindColors.gray[300])
      .attr("stroke-dasharray", "4, 4")

    this.#d3Svg
      .append("circle")
      .attr("cx", this.#d3Svg.node().clientWidth / 2)
      .attr("cy", this.#d3Svg.node().clientHeight / 2)
      .attr("r", 4)
      .style("fill", tailwindColors.gray[400])
  }

  #drawLine() {
    this.#d3Svg
      .append("path")
      .datum(this.#dataPoints)
      .attr("fill", "none")
      .attr("stroke", this.#trendColor)
      .attr("stroke-width", 2)
      .attr("d", this.#d3Line);
  }

  #createD3Svg() {
    const height = this.#d3ContainerHeight
    const width = this.#d3ContainerWidth

    return this.#d3Container
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [ 0, 0, width, height ])
  }

  get #dataPoints() {
    return this.#_dataPoints
  }

  set #dataPoints(dataPoints) {
    this.#_dataPoints = dataPoints
  }

  get #d3Svg() {
    if (this.#_d3Svg) {
      return this.#_d3Svg
    } else {
      return this.#_d3Svg = this.#createD3Svg()
    }
  }

  get #d3ContainerWidth() {
    return this.#d3Container.node().clientWidth
  }

  get #d3ContainerHeight() {
    return this.#d3Container.node().clientHeight
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
      .rangeRound([0, this.#d3ContainerWidth])
      .domain(d3.extent(this.#dataPoints, d => d.date))
  }

  get #d3YScale() {
    const PADDING = 0.05
    const dataMin = d3.min(this.#dataPoints, d => d.value)
    const dataMax = d3.max(this.#dataPoints, d => d.value)
    const padding = (dataMax - dataMin) * PADDING

    return d3
      .scaleLinear()
      .rangeRound([this.#d3ContainerHeight, 0])
      .domain([dataMin - padding, dataMax + padding])
  }
}
