import { widgetStates } from "./mock-data.js";

const defaultStateKey = "printing";

const stageConfig = [
  { size: "small", title: "systemSmall", summary: "最小信息集" },
  { size: "medium", title: "systemMedium", summary: "主展示尺寸" },
  { size: "large", title: "systemLarge", summary: "完整状态摘要" }
];

const buttons = Array.from(document.querySelectorAll(".state-switcher button"));
const stages = Array.from(document.querySelectorAll(".widget-stage"));
const footer = document.querySelector(".footer-note p");

function setActiveButton(stateKey) {
  buttons.forEach((button) => {
    const isActive = button.dataset.state === stateKey;
    button.classList.toggle("is-active", isActive);
  });
}

function percentWidth(value) {
  const clamped = Math.min(Math.max(value, 0), 1);
  return `${Math.round(clamped * 100)}%`;
}

function buildMetrics(state, size) {
  if (size === "small") {
    return "";
  }

  const primary = `
    <div class="metric">
      <span class="metric-label">喷嘴</span>
      <span class="metric-value">${state.nozzle}</span>
    </div>
    <div class="metric">
      <span class="metric-label">热床</span>
      <span class="metric-value">${state.bed}</span>
    </div>
    <div class="metric">
      <span class="metric-label">剩余</span>
      <span class="metric-value">${state.remainingTime}</span>
    </div>
  `;

  if (size !== "large") {
    return primary;
  }

  return `
    ${primary}
    <div class="metric">
      <span class="metric-label">层数</span>
      <span class="metric-value">${state.layer}</span>
    </div>
    <div class="metric">
      <span class="metric-label">倍率</span>
      <span class="metric-value">${state.speed}</span>
    </div>
  `;
}

function buildStage(state, config) {
  return `
    <div class="stage-meta">
      <span class="stage-label">${config.title}</span>
      <span class="stage-summary">${config.summary}</span>
    </div>
    <div class="widget-frame size-${config.size} tone-${state.tone}">
      <div class="widget-card">
        <div class="widget-header">
          <span class="status-pill">${state.statusLabel}</span>
          <span class="connection-label">${state.connectionLabel}</span>
        </div>
        <div class="widget-title">${state.title}</div>
        <div class="progress-block">
          <div class="progress-value">${state.progressLabel}</div>
          <div class="progress-track">
            <div class="progress-fill" style="width: ${percentWidth(state.progress)};"></div>
          </div>
        </div>
        <div class="metrics ${config.size === "small" ? "is-hidden" : ""}">
          ${buildMetrics(state, config.size)}
        </div>
        <div class="widget-summary">${state.summary}</div>
      </div>
    </div>
  `;
}

function render(stateKey) {
  const state = widgetStates[stateKey] || widgetStates[defaultStateKey];
  setActiveButton(stateKey);
  stages.forEach((stage) => {
    const size = stage.dataset.size || "medium";
    const config = stageConfig.find((item) => item.size === size) || stageConfig[1];
    stage.dataset.state = stateKey;
    stage.innerHTML = buildStage(state, config);
  });
  if (footer) {
    footer.textContent = `当前状态：${state.statusLabel}。三种尺寸同步展示。`;
  }
}

render(defaultStateKey);

buttons.forEach((button) => {
  button.addEventListener("click", () => {
    const stateKey = button.dataset.state;
    if (!stateKey) {
      return;
    }
    render(stateKey);
  });
});
