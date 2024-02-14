import { Controller } from "@hotwired/stimulus";
import { select, selectAll } from "d3-selection";
import { scaleTime, scaleLinear } from "d3-scale";
import { max, extent } from "d3-array";
import { axisBottom, axisLeft } from "d3-axis";
import { line as d3Line, area as d3Area } from "d3-shape";
import tailwindColors from "@maybe/tailwindcolors";

// Connects to data-controller="line-chart"
export default class extends Controller {
  connect() {
    this.resizeChart();
    window.addEventListener("resize", () => this.resizeChart());
    this.drawChart();
  }

  resizeChart() {
    const chart = document.querySelector("#lineChart");
    const width = 800; // Dynamically grab the width
    const height = 400; // Explicitly set the height
    chart.style.height = `${height}px`;
    chart.style.width = `${width}px`;
  }

  drawChart() {
    const chart = document.querySelector("#lineChart");
    const _width = chart.offsetWidth; // Dynamically grab the width for initial value
    const _height = 400;
    const data = [
      { date: new Date(2021, 0, 1), value: 30 },
      { date: new Date(2021, 0, 2), value: 40 },
      // Add more data points as needed
    ];

    const svg = select("#lineChart")
      .append("svg")
      .attr("width", _width)
      .attr("height", _height);
    const margin = { top: 20, right: 0, bottom: 30, left: 0 },
      width = +svg.attr("width") - margin.left - margin.right,
      height = +svg.attr("height") - margin.top - margin.bottom,
      g = svg
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);
    const x = scaleTime()
      .rangeRound([0, width])
      .domain(extent(data, (d) => d.date));
    const y = scaleLinear()
      .rangeRound([height, 0])
      .domain([0, max(data, (d) => d.value)]);
    const line = d3Line()
      .x((d) => x(d.date))
      .y((d) => y(d.value));
    g.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(
        axisBottom(x).tickValues([data[0].date, data[data.length - 1].date])
      )
      .select(".domain")
      .remove();
    g.append("path")
      .datum(data)
      .attr("fill", "none")
      .attr("stroke", tailwindColors.green[500])
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", 1.5)
      .attr("class", "line-chart-path")
      .attr("d", line);

    // Add gradient under the line
    const areaGradient = svg
      .append("defs")
      .append("linearGradient")
      .attr("id", "areaGradient")
      .attr("x1", 0)
      .attr("y1", 0)
      .attr("x2", 0)
      .attr("y2", 1);
    areaGradient
      .append("stop")
      .attr("offset", "0%")
      .attr("stop-color", tailwindColors.green[500])
      .attr("stop-opacity", 0.3); // Made the gradient more subtle by reducing the opacity
    areaGradient
      .append("stop")
      .attr("offset", "100%")
      .attr("stop-color", tailwindColors.green[500])
      .attr("stop-opacity", 0); // Ensures the gradient fades to transparent

    const area = d3Area()
      .x((d) => x(d.date))
      .y0(height)
      .y1((d) => y(d.value));

    g.append("path")
      .datum(data)
      .attr("class", "line-chart-area")
      .attr("fill", "url(#areaGradient)")
      .attr("d", area);
  }
}
