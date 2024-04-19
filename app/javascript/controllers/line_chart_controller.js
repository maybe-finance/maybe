import { Controller } from "@hotwired/stimulus";
import tailwindColors from "@maybe/tailwindcolors";
import * as d3 from "d3";

// Connects to data-controller="line-chart"
export default class extends Controller {
  static values = { series: Object, label: String, tooltip: String, classification: String };

  connect() {
    this.renderChart(this.seriesValue);
    document.addEventListener("turbo:load", this.renderChart);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.renderChart);
  }

  renderChart = () => {
    const data = this.prepareData(this.seriesValue);
    this.drawChart(data);
  };

  trendStyles(trendDirection) {
    return {
      up: {
        icon: "↑",
        color: tailwindColors.success,
      },
      down: {
        icon: "↓",
        color: tailwindColors.error,
      },
      flat: {
        icon: "→",
        color: tailwindColors.gray[500],
      },
    }[trendDirection];
  }

  prepareData(series) {
    return series.values.map((b) => ({
      date: new Date(b.date + "T00:00:00"),
      value: b.value.amount ? +b.value.amount : +b.value,
      styles: this.trendStyles(b.trend.direction),
      trend: b.trend,
      formatted: {
        value: Intl.NumberFormat(undefined, {
          style: "currency",
          currency: b.value.currency || "USD",
        }).format(b.value.amount),
        change: Intl.NumberFormat(undefined, {
          style: "currency",
          currency: b.value.currency || "USD",
          signDisplay: "always",
        }).format(b.trend.value.amount),
      },
    }));
  }

  drawChart(data) {
    const chartContainer = d3.select(this.element);

    // Clear any existing chart
    chartContainer.selectAll("svg").remove();

    const initialDimensions = {
      width: chartContainer.node().clientWidth,
      height: chartContainer.node().clientHeight,
    };

    const svg = chartContainer
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

    if (data.length <= 1) {
      this.renderEmpty(svg, initialDimensions);
      return;
    }

    const margin = { top: 20, right: 1, bottom: 30, left: 1 },
      width = +svg.attr("width") - margin.left - margin.right,
      height = +svg.attr("height") - margin.top - margin.bottom,
      g = svg
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);
    
    const isLiability = this.classificationValue === "liability";
    const trendDirection = data[data.length - 1].value - data[0].value;
    let lineColor;

    if (trendDirection > 0) {
      lineColor = isLiability
        ? tailwindColors.error
        : tailwindColors.green[500];
    } else if (trendDirection < 0) {
      lineColor = isLiability
        ? tailwindColors.green[500]
        : tailwindColors.error;
    } else {
      lineColor = tailwindColors.gray[500];
    }

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

    const isLabelDisabled = this.labelValue === "disable";

    if(!isLabelDisabled){
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
    }

    // Line
    const line = d3
      .line()
      .x((d) => x(d.date))
      .y((d) => y(d.value));

    g.append("path")
      .datum(data)
      .attr("fill", "none")
      .attr("stroke", lineColor)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("stroke-width", 1.5)
      .attr("class", "line-chart-path")
      .attr("d", line);

    const isTooltipDisabled = this.tooltipValue === "disable";

    if(!isTooltipDisabled){
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
          tooltip.style("opacity", 1);
  
          const tooltipWidth = 250; // Estimate or dynamically calculate the tooltip width
          const pageWidth = document.body.clientWidth;
          const tooltipX = event.pageX + 10;
          const overflowX = tooltipX + tooltipWidth - pageWidth;
  
          const [xPos] = d3.pointer(event);
  
          const x0 = bisectDate(data, x.invert(xPos), 1);
          const d0 = data[x0 - 1];
          const d1 = data[x0];
          const d = xPos - x(d0.date) > x(d1.date) - xPos ? d1 : d0;
  
          // Adjust tooltip position based on overflow
          const adjustedX =
            overflowX > 0 ? event.pageX - overflowX - 20 : tooltipX;
  
          g.selectAll(".data-point-circle").remove(); // Remove existing circles to ensure only one is shown at a time
          g.append("circle")
            .attr("class", "data-point-circle")
            .attr("cx", x(d.date))
            .attr("cy", y(d.value))
            .attr("r", 8)
            .attr("fill", lineColor)
            .attr("fill-opacity", "0.1")
            .attr("pointer-events", "none");
  
          g.append("circle")
            .attr("class", "data-point-circle")
            .attr("cx", x(d.date))
            .attr("cy", y(d.value))
            .attr("r", 3)
            .attr("fill", lineColor)
            .attr("pointer-events", "none");
  
          tooltip
            .html(
              `<div style="margin-bottom: 4px; color: ${
                tailwindColors.gray[500]
              }">${d3.timeFormat("%b %d, %Y")(d.date)}</div>
                   <div style="display: flex; align-items: center; gap: 8px;">
                     <svg width="10" height="10">
                       <circle cx="5" cy="5" r="4" stroke="${
                         d.styles.color
                       }" fill="transparent" stroke-width="1"></circle>
                     </svg>
                     ${d.formatted.value} <span style="color: ${
                d.styles.color
              };">${d.formatted.change} (${d.trend.percent}%)</span>
              </div>`
            )
            .style("left", adjustedX + "px")
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

  // Dot in middle of chart as placeholder for empty chart
  renderEmpty(svg, { width, height }) {
    svg
      .append("line")
      .attr("x1", width / 2)
      .attr("y1", 0)
      .attr("x2", width / 2)
      .attr("y2", height)
      .attr("stroke", tailwindColors.gray[300])
      .attr("stroke-dasharray", "4, 4");

    svg
      .append("circle")
      .attr("cx", width / 2)
      .attr("cy", height / 2)
      .attr("r", 4)
      .style("fill", tailwindColors.gray[400]);

    svg.selectAll(".tick").remove();
    svg.selectAll(".domain").remove();
  }
}
