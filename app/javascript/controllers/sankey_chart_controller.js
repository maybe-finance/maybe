import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";
import { sankey, sankeyLinkHorizontal } from "d3-sankey";

// Connects to data-controller="sankey-chart"
export default class extends Controller {
  static values = {
    data: Object,
    nodeWidth: { type: Number, default: 15 },
    nodePadding: { type: Number, default: 20 },
    currencySymbol: { type: String, default: "$" }
  };

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.#draw());
    this.resizeObserver.observe(this.element);
    this.#draw();
  }

  disconnect() {
    this.resizeObserver?.disconnect();
  }

  #draw() {
    const { nodes = [], links = [] } = this.dataValue || {};

    if (!nodes.length || !links.length) return;

    // Clear previous SVG
    d3.select(this.element).selectAll("svg").remove();

    const width = this.element.clientWidth || 600;
    const height = this.element.clientHeight || 400;

    const svg = d3
      .select(this.element)
      .append("svg")
      .attr("width", width)
      .attr("height", height);

    const sankeyGenerator = sankey()
      .nodeWidth(this.nodeWidthValue)
      .nodePadding(this.nodePaddingValue)
      .extent([
        [16, 16],
        [width - 16, height - 16],
      ]);

    const sankeyData = sankeyGenerator({
      nodes: nodes.map((d) => Object.assign({}, d)),
      links: links.map((d) => Object.assign({}, d)),
    });

    // Define gradients for links
    const defs = svg.append("defs");

    sankeyData.links.forEach((link, i) => {
      const gradientId = `link-gradient-${link.source.index}-${link.target.index}-${i}`;

      const getStopColorWithOpacity = (nodeColorInput, opacity = 0.1) => {
        let colorStr = nodeColorInput || "var(--color-gray-400)";
        if (colorStr === "var(--color-success)") {
          colorStr = "#10A861"; // Hex for --color-green-600
        }
        // Add other CSS var to hex mappings here if needed

        if (colorStr.startsWith("var(--")) { // Unmapped CSS var, use as is (likely solid)
          return colorStr;
        }

        const d3Color = d3.color(colorStr);
        return d3Color ? d3Color.copy({ opacity: opacity }) : "var(--color-gray-400)";
      };

      const sourceStopColor = getStopColorWithOpacity(link.source.color);
      const targetStopColor = getStopColorWithOpacity(link.target.color);

      const gradient = defs.append("linearGradient")
        .attr("id", gradientId)
        .attr("gradientUnits", "userSpaceOnUse")
        .attr("x1", link.source.x1)
        .attr("x2", link.target.x0);

      gradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", sourceStopColor);

      gradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", targetStopColor);
    });

    // Draw links
    svg
      .append("g")
      .attr("fill", "none")
      .selectAll("path")
      .data(sankeyData.links)
      .join("path")
      .attr("d", (d) => {
        const sourceX = d.source.x1;
        const targetX = d.target.x0;
        const path = d3.linkHorizontal()({
          source: [sourceX, d.y0],
          target: [targetX, d.y1]
        });
        return path;
      })
      .attr("stroke", (d, i) => `url(#link-gradient-${d.source.index}-${d.target.index}-${i})`)
      .attr("stroke-width", (d) => Math.max(1, d.width))
      .append("title")
      .text((d) => `${nodes[d.source.index].name} → ${nodes[d.target.index].name}: ${this.currencySymbolValue}${Number.parseFloat(d.value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} (${d.percentage}%)`);

    // Draw nodes
    const node = svg
      .append("g")
      .selectAll("g")
      .data(sankeyData.nodes)
      .join("g");

    const cornerRadius = 8;

    node.append("path")
      .attr("d", (d) => {
        const x0 = d.x0;
        const y0 = d.y0;
        const x1 = d.x1;
        const y1 = d.y1;
        const h = y1 - y0;
        // const w = x1 - x0; // Not directly used in path string, but good for context

        // Dynamic corner radius based on node height, maxed at 8
        const effectiveCornerRadius = Math.max(0, Math.min(cornerRadius, h / 2));

        const isSourceNode = d.sourceLinks && d.sourceLinks.length > 0 && (!d.targetLinks || d.targetLinks.length === 0);
        const isTargetNode = d.targetLinks && d.targetLinks.length > 0 && (!d.sourceLinks || d.sourceLinks.length === 0);

        if (isSourceNode) { // Round left corners, flat right for "Total Income"
          if (h < effectiveCornerRadius * 2) {
            return `M ${x0},${y0} L ${x1},${y0} L ${x1},${y1} L ${x0},${y1} Z`;
          }
          return `M ${x0 + effectiveCornerRadius},${y0}
                  L ${x1},${y0}
                  L ${x1},${y1}
                  L ${x0 + effectiveCornerRadius},${y1}
                  Q ${x0},${y1} ${x0},${y1 - effectiveCornerRadius}
                  L ${x0},${y0 + effectiveCornerRadius}
                  Q ${x0},${y0} ${x0 + effectiveCornerRadius},${y0} Z`;
        }

        if (isTargetNode) { // Flat left corners, round right for Categories/Surplus
          if (h < effectiveCornerRadius * 2) {
            return `M ${x0},${y0} L ${x1},${y0} L ${x1},${y1} L ${x0},${y1} Z`;
          }
          return `M ${x0},${y0}
                  L ${x1 - effectiveCornerRadius},${y0}
                  Q ${x1},${y0} ${x1},${y0 + effectiveCornerRadius}
                  L ${x1},${y1 - effectiveCornerRadius}
                  Q ${x1},${y1} ${x1 - effectiveCornerRadius},${y1}
                  L ${x0},${y1} Z`;
        }

        // Fallback for intermediate nodes (e.g., "Cash Flow") - draw as a simple sharp-cornered rectangle
        return `M ${x0},${y0} L ${x1},${y0} L ${x1},${y1} L ${x0},${y1} Z`;
      })
      .attr("fill", (d) => d.color || "var(--color-gray-400)")
      .attr("stroke", (d) => {
        // If a node has an explicit color assigned (even if it's a gray variable),
        // it gets no stroke. Only truly un-colored nodes (falling back to default fill)
        // would get a stroke, but our current data structure assigns colors to all nodes.
        if (d.color) {
          return "none";
        }
        return "var(--color-gray-500)"; // Fallback, likely unused with current data
      });

    const stimulusControllerInstance = this;
    node
      .append("text")
      .attr("x", (d) => (d.x0 < width / 2 ? d.x1 + 6 : d.x0 - 6))
      .attr("y", (d) => (d.y1 + d.y0) / 2)
      .attr("dy", "-0.2em")
      .attr("text-anchor", (d) => (d.x0 < width / 2 ? "start" : "end"))
      .attr("class", "text-xs font-medium text-primary fill-current")
      .each(function (d) {
        const textElement = d3.select(this);
        textElement.selectAll("tspan").remove();

        // Node Name on the first line
        textElement.append("tspan")
          .text(d.name);

        // Financial details on the second line
        const financialDetailsTspan = textElement.append("tspan")
          .attr("x", textElement.attr("x"))
          .attr("dy", "1.2em")
          .attr("class", "font-mono text-secondary")
          .style("font-size", "0.65rem"); // Explicitly set smaller font size

        financialDetailsTspan.append("tspan")
          .text(stimulusControllerInstance.currencySymbolValue + Number.parseFloat(d.value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
      });
  }
} 