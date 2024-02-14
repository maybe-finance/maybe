import { Controller } from "@hotwired/stimulus";
import tailwindColors from "@maybe/tailwindcolors";
import * as d3 from "d3";

// Connects to data-controller="line-chart"
export default class extends Controller {
  connect() {
    this.drawChart();
  }

  drawChart() {
    // TODO: Replace with live data through controller targets
    const data = [
      {
        date: new Date(2021, 0, 1),
        value: 985000,
        formatted: "$985,000",
        change: { value: "$0", direction: "none", percentage: "0%" },
      },
      {
        date: new Date(2021, 1, 1),
        value: 990000,
        formatted: "$990,000",
        change: { value: "$5,000", direction: "up", percentage: "0.51%" },
      },
      {
        date: new Date(2021, 2, 1),
        value: 995000,
        formatted: "$995,000",
        change: { value: "$5,000", direction: "up", percentage: "0.51%" },
      },
      {
        date: new Date(2021, 3, 1),
        value: 1000000,
        formatted: "$1,000,000",
        change: { value: "$5,000", direction: "up", percentage: "0.50%" },
      },
      {
        date: new Date(2021, 4, 1),
        value: 1005000,
        formatted: "$997,000",
        change: { value: "$3,000", direction: "down", percentage: "-0.30%" },
      },
      {
        date: new Date(2021, 5, 1),
        value: 1010000,
        formatted: "$1,010,000",
        change: { value: "$5,000", direction: "up", percentage: "0.50%" },
      },
      {
        date: new Date(2021, 6, 1),
        value: 1050000,
        formatted: "$1,050,000",
        change: { value: "$40,000", direction: "up", percentage: "3.96%" },
      },
      {
        date: new Date(2021, 7, 1),
        value: 1080000,
        formatted: "$1,080,000",
        change: { value: "$30,000", direction: "up", percentage: "2.86%" },
      },
      {
        date: new Date(2021, 8, 1),
        value: 1100000,
        formatted: "$1,100,000",
        change: { value: "$20,000", direction: "up", percentage: "1.85%" },
      },
      {
        date: new Date(2021, 9, 1),
        value: 1115181,
        formatted: "$1,115,181",
        change: { value: "$15,181", direction: "up", percentage: "1.38%" },
      },
    ];

    const initialDimensions = {
      width: document.querySelector("#lineChart").clientWidth,
      height: document.querySelector("#lineChart").clientHeight,
    };

    const svg = d3
      .select("#lineChart")
      .append("svg")
      .attr("width", initialDimensions.width)
      .attr("height", initialDimensions.height)
      .attr("viewBox", [
        0,
        0,
        initialDimensions.width,
        initialDimensions.height,
      ])
      .attr("style", "max-width: 100%; height: auto; height: intrinsic;");

    const margin = { top: 20, right: 0, bottom: 30, left: 0 },
      width = +svg.attr("width") - margin.left - margin.right,
      height = +svg.attr("height") - margin.top - margin.bottom,
      g = svg
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);

    // X-Axis
    const x = d3
      .scaleTime()
      .rangeRound([0, width])
      .domain(d3.extent(data, (d) => d.date));

    const PADDING = 0.15; // 15% padding on top and bottom of data
    const dataMin = d3.min(data, (d) => d.value);
    const dataMax = d3.max(data, (d) => d.value);
    const padding = (dataMax - dataMin) * PADDING;

    // Y-Axis
    const y = d3
      .scaleLinear()
      .rangeRound([height, 0])
      .domain([dataMin - padding, dataMax + padding]);

    // X-Axis labels
    g.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(
        d3
          .axisBottom(x)
          .tickValues([data[0].date, data[data.length - 1].date])
          .tickSize(0)
          .tickFormat(d3.timeFormat("%b %Y"))
      )
      .select(".domain")
      .remove();

    g.selectAll(".tick text")
      .style("fill", tailwindColors.gray[500])
      .style("font-size", "12px")
      .style("font-weight", "500")
      .attr("text-anchor", "middle")
      .attr("dx", (d, i) => {
        // We know we only have 2 values
        return i === 0 ? "5em" : "-5em";
      })
      .attr("dy", "0em");

    // Line
    const line = d3
      .line()
      .x((d) => x(d.date))
      .y((d) => y(d.value));

    g.append("path")
      .datum(data)
      .attr("fill", "none")
      .attr("stroke", tailwindColors.green[500])
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", 1.5)
      .attr("class", "line-chart-path")
      .attr("d", line);

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
      .style("opacity", 0); // Starts as hidden

    // Helper to find the closest data point to the mouse
    const bisectDate = d3.bisector(function (d) {
      return d.date;
    }).left;

    // Create an invisible rectangle that captures mouse events (regular SVG elements don't capture mouse events by default)
    g.append("rect")
      .attr("width", width)
      .attr("height", height)
      .attr("fill", "none")
      .attr("pointer-events", "all")
      // When user hovers over the chart, show the tooltip and a circle at the closest data point
      .on("mousemove", (event) => {
        console.log("mouse showing");
        tooltip.style("opacity", 1);

        const [xPos] = d3.pointer(event);

        const x0 = bisectDate(data, x.invert(xPos));
        const d0 = data[x0 - 1];
        const d1 = data[x0];
        const d = xPos - x(d0.date) > x(d1.date) - xPos ? d1 : d0;

        g.selectAll(".data-point-circle").remove(); // Remove existing circles to ensure only one is shown at a time
        g.append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", x(d.date))
          .attr("cy", y(d.value))
          .attr("r", 8)
          .attr("fill", tailwindColors.green[500])
          .attr("fill-opacity", "0.1");

        g.append("circle")
          .attr("class", "data-point-circle")
          .attr("cx", x(d.date))
          .attr("cy", y(d.value))
          .attr("r", 3)
          .attr("fill", tailwindColors.green[500]);

        tooltip
          .html(
            `<div style="margin-bottom: 4px; color: ${
              tailwindColors.gray[500]
            }">${d3.timeFormat("%b %Y")(d.date)}</div>
                 <div style="display: flex; align-items: center; gap: 8px;">
                   <svg width="10" height="10">
                     <circle cx="5" cy="5" r="4" stroke="${
                       d.change.direction === "up"
                         ? tailwindColors.success
                         : d.change.direction === "down"
                         ? tailwindColors.error
                         : tailwindColors.gray[500]
                     }" fill="transparent" stroke-width="1"></circle>
                   </svg>
                   ${d.formatted} <span style="color: ${
              d.change.direction === "up"
                ? tailwindColors.success
                : d.change.direction === "down"
                ? tailwindColors.error
                : tailwindColors.gray[500]
            };"><span>${
              d.change.direction === "up"
                ? "+"
                : d.change.direction === "down"
                ? "-"
                : ""
            }</span>${d.change.value} (${d.change.percentage})</span>
                 
                 </div>`
          )
          .style("left", event.pageX + 10 + "px")
          .style("top", event.pageY - 10 + "px");

        g.selectAll(".guideline").remove(); // Remove existing line to ensure only one is shown at a time
        g.append("line")
          .attr("class", "guideline")
          .attr("x1", x(d.date))
          .attr("y1", 0)
          .attr("x2", x(d.date))
          .attr("y2", height)
          .attr("stroke", tailwindColors.gray[300])
          .attr("stroke-dasharray", "4, 4");
      })
      .on("mouseout", () => {
        g.selectAll(".guideline").remove();
        g.selectAll(".data-point-circle").remove();
        tooltip.style("opacity", 0);
      });
  }
}
