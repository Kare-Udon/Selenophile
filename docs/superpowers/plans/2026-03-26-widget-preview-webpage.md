# Widget Preview Webpage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a locally previewable web page that shows the Selenophile macOS widget design in `systemSmall`, `systemMedium`, and `systemLarge` sizes across the four target states.

**Architecture:** Implement the preview as a small static site at the repo root so it can be opened in a browser without any build tooling. Keep data, rendering, and styling separated into focused files: one HTML shell, one stylesheet, and one JavaScript entry point with mock widget state. The page should render three side-by-side widget frames on desktop and fall back to a stacked layout on narrow screens.

**Tech Stack:** Plain HTML5, CSS3, vanilla JavaScript, local static file serving via `python3 -m http.server`.

---

### Task 1: Scaffold the static preview site

**Files:**
- Create: `WidgetPreview/index.html`
- Create: `WidgetPreview/styles.css`
- Create: `WidgetPreview/main.js`
- Create: `WidgetPreview/mock-data.js`
- Create: `WidgetPreview/README.md`

- [ ] **Step 1: Create the empty page shell**

`WidgetPreview/index.html` should contain:

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Selenophile Widget Preview</title>
    <link rel="stylesheet" href="./styles.css" />
  </head>
  <body>
    <main class="app-shell">
      <header class="hero">
        <p class="eyebrow">Selenophile</p>
        <h1>Widget Preview</h1>
        <p class="subtitle">并排查看 systemSmall、systemMedium、systemLarge 的视觉与信息密度。</p>
      </header>

      <section class="state-switcher" aria-label="状态切换">
        <button type="button" data-state="printing" class="is-active">打印中</button>
        <button type="button" data-state="idle">已连接空闲</button>
        <button type="button" data-state="error">断开 / 失败</button>
        <button type="button" data-state="unconfigured">未配置</button>
      </section>

      <section class="widget-grid" aria-label="widget 预览">
        <article class="widget-stage" data-size="small"></article>
        <article class="widget-stage" data-size="medium"></article>
        <article class="widget-stage" data-size="large"></article>
      </section>

      <footer class="footer-note">
        <p>默认状态展示打印中；切换按钮会同步更新三种尺寸。</p>
      </footer>
    </main>

    <script type="module" src="./main.js"></script>
  </body>
</html>
```

- [ ] **Step 2: Add the mock widget state payload**

`WidgetPreview/mock-data.js` should export a single state map so the UI can render the same payload in different sizes:

```js
export const widgetStates = {
  printing: {
    statusLabel: "打印中",
    connectionLabel: "已连接",
    title: "Benchy_0.2mm.gcode",
    progress: 0.64,
    progressLabel: "64%",
    remainingTime: "00:28:40",
    elapsedTime: "00:49:20",
    nozzle: "215 / 220°C",
    bed: "63 / 65°C",
    layer: "124 / 196",
    speed: "100%",
    summary: "正在稳定打印，状态正常",
    tone: "accent"
  },
  idle: {
    statusLabel: "待机",
    connectionLabel: "已连接",
    title: "等待打印任务",
    progress: 0,
    progressLabel: "0%",
    remainingTime: "--:--:--",
    elapsedTime: "--:--:--",
    nozzle: "--",
    bed: "--",
    layer: "--",
    speed: "--",
    summary: "打印机已连接，当前没有活动任务",
    tone: "muted"
  },
  error: {
    statusLabel: "连接失败",
    connectionLabel: "已断开",
    title: "Moonraker 连接异常",
    progress: 0.18,
    progressLabel: "18%",
    remainingTime: "暂停",
    elapsedTime: "已中断",
    nozzle: "—",
    bed: "—",
    layer: "—",
    speed: "—",
    summary: "请检查 Moonraker 地址或网络连接",
    tone: "danger"
  },
  unconfigured: {
    statusLabel: "未配置",
    connectionLabel: "待配置",
    title: "请先设置 Moonraker 地址",
    progress: 0,
    progressLabel: "0%",
    remainingTime: "--",
    elapsedTime: "--",
    nozzle: "--",
    bed: "--",
    layer: "--",
    speed: "--",
    summary: "还没有可用的打印状态数据",
    tone: "neutral"
  }
};
```

- [ ] **Step 3: Document the run flow**

`WidgetPreview/README.md` should explain:

```md
# Selenophile Widget Preview

Run:

`python3 -m http.server 4173 --directory WidgetPreview`

Open:

`http://localhost:4173`
```

- [ ] **Step 4: Verify the shell loads in a browser**

Run:

```bash
python3 -m http.server 4173 --directory WidgetPreview
```

Expected:
- The page opens without console errors
- The hero text, state switcher, and three empty widget stages are visible
- The page still reads cleanly if JavaScript is temporarily disabled

---

### Task 2: Build the widget card layout and visual system

**Files:**
- Modify: `WidgetPreview/styles.css`
- Modify: `WidgetPreview/main.js`

- [ ] **Step 1: Implement the page-level visual language**

`styles.css` should define:

```css
:root {
  color-scheme: light;
  --bg-1: #edf2f7;
  --bg-2: #f7f9fc;
  --card: rgba(255, 255, 255, 0.78);
  --card-border: rgba(255, 255, 255, 0.72);
  --text-strong: #101826;
  --text: #3c4b5c;
  --text-muted: #6f7f93;
  --accent: #ff8a55;
  --accent-weak: rgba(255, 138, 85, 0.18);
  --danger: #d95d55;
  --shadow: 0 24px 60px rgba(16, 24, 38, 0.10);
}
```

Use the variables to build:
- a soft gradient page background
- a restrained hero area
- a 3-column stage grid on wide screens
- stacked layout below tablet widths

- [ ] **Step 2: Render size-specific frames**

`main.js` should render three frames with these containers:

```js
const stageConfig = [
  { size: "small", title: "systemSmall", summary: "最小信息集" },
  { size: "medium", title: "systemMedium", summary: "主展示尺寸" },
  { size: "large", title: "systemLarge", summary: "完整状态摘要" }
];
```

Each stage should include:
- a size label
- a widget frame
- a short descriptive caption

- [ ] **Step 3: Implement the card hierarchy**

The card body should use a consistent hierarchy:
- status pill on the top line
- task name as the primary text
- progress as the visual center
- metrics as the secondary row
- error or empty-state copy when applicable

For `systemSmall`, suppress the metrics row entirely.
For `systemLarge`, add the extra fields for layer count and feed rate.

- [ ] **Step 4: Verify visual balance at desktop width**

Open `http://localhost:4173` at a desktop viewport width.

Expected:
- The three cards align on one baseline
- `systemMedium` reads as the most balanced card
- `systemSmall` does not feel crowded
- `systemLarge` does not look like a dashboard

---

### Task 3: Add state switching and data-driven rendering

**Files:**
- Modify: `WidgetPreview/main.js`
- Modify: `WidgetPreview/styles.css`

- [ ] **Step 1: Render the active state from the mock data**

`main.js` should keep one `activeStateKey` and derive the visible payload from `widgetStates[activeStateKey]`.

Use a single render function to update:
- the active button styles
- the three stages
- the footer note

- [ ] **Step 2: Wire the switcher buttons**

Button behavior:
- clicking `打印中` sets `activeStateKey = "printing"`
- clicking `已连接空闲` sets `activeStateKey = "idle"`
- clicking `断开 / 失败` sets `activeStateKey = "error"`
- clicking `未配置` sets `activeStateKey = "unconfigured"`

Update the active button with the class `is-active`.

- [ ] **Step 3: Map tone classes to the widget frame**

Add tone-specific classes on the widget frame:
- `tone-accent`
- `tone-muted`
- `tone-danger`
- `tone-neutral`

Use them to change the progress bar, status pill, and summary text without changing layout.

- [ ] **Step 4: Verify all four states**

Manually click through each state and confirm:
- the three stages update together
- the text changes match the active state
- the layout does not jump
- the error and unconfigured states visually soften the content instead of reshaping the card

---

### Task 4: Polish responsiveness, accessibility, and visual fidelity

**Files:**
- Modify: `WidgetPreview/styles.css`
- Modify: `WidgetPreview/main.js`

- [ ] **Step 1: Add responsive fallback behavior**

At narrower widths, stack the three stages vertically and reduce side padding so the preview still fits on smaller laptops.

Use a breakpoint around `960px` for the first layout shift and a second breakpoint around `640px` for denser spacing.

- [ ] **Step 2: Improve keyboard and semantic behavior**

Ensure:
- each state button remains a real `button`
- the active state is visible with an obvious focus ring
- the preview grid uses semantic `section` / `article` structure
- color contrast remains readable in all four states

- [ ] **Step 3: Add subtle motion only where it helps**

Keep motion minimal:
- soft transition on state changes
- gentle hover lift on the widget stages
- no looping animation

- [ ] **Step 4: Run a final visual pass**

Checklist:
- the page feels like a desktop widget canvas, not a generic website
- the typography is calm and crisp
- the warm accent is present but not loud
- the cards look like siblings, not separate components

---

### Task 5: Record the preview workflow

**Files:**
- Modify: `WidgetPreview/README.md`

- [ ] **Step 1: Add a short usage note**

Document:
- how to start the local server
- which URL to open
- what the four states represent
- that the page is meant for visual review before native WidgetKit implementation

- [ ] **Step 2: Confirm the repo is clean**

Run:

```bash
git status --short
```

Expected:
- only the new preview files under `WidgetPreview/` should remain uncommitted if the plan document has already been committed
- if the plan document has not been committed yet, it may also appear in the status output

- [ ] **Step 3: Commit the preview work**

Use a focused commit message such as:

```bash
git add WidgetPreview docs/superpowers/plans/2026-03-26-widget-preview-webpage.md
git commit -m "feat: add widget preview webpage"
```
