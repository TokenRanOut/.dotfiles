# Complete high-fidelity page analysis

Read when the user or command explicitly requests complete collection or visual fidelity. Cross-check page structure, text, images, rich text, and visual states in the current session to produce a traceable Chinese summary. Use the main skill's lightweight route for ordinary goal-directed queries.

Do not create or delegate to other agents. Perform page reading, snapshots, and summarization in the current agent.

The caller may override the analysis goal and return format, but not reduce this reference's fidelity baseline. A different output format must still preserve equivalent evidence paths, coverage statistics, and unresolved content. Skip a content category only when the caller explicitly requests ignoring it.

## Fidelity principles

1. Accessibility Markdown snapshots provide structure and accessible text; they do not prove complete extraction.
2. Combine three evidence types: accessibility snapshots, DOM/computed styles, and page or element screenshots. Record conflicts separately instead of choosing or correcting one yourself.
3. Missing alt text, absent snapshot text, or styles omitted by Markdown do not prove that image or visual information is unreadable.
4. Color, strikethrough, highlighting, bold text, badges, and control states may carry business meaning. Preserve the original text, styles, and context. Interpret business meaning only when explicitly explained by page legends or copy; otherwise state visual facts only.
5. For content that cannot be reliably identified, record its location, medium, attempted methods, and unresolved scope. Do not silently omit it or guess.
6. Deeply extract all content-bearing images and visual components by default. Classify an item as decorative and summarize it only when DOM metadata, context, and screenshots jointly show that it carries no independent information. Treat uncertain classification as an unresolved visual item rather than skipping it as decoration.

## Workflow

1. Load or reuse `playwright-cli`. Use only its CLI browser workflow, not Playwright MCP, and start a unique task session. Save evidence in a task-unique subdirectory of the runtime-provided temporary root, or the system temporary directory if none is provided; call this `<evidence-directory>`. Use absolute paths; do not rely on a title and minute-level timestamp as the only unique identifier.
2. Wait for the main content to stabilize and identify the document and relevant internal scroll containers. Scroll one viewport at a time to trigger lazy loading. After every viewport change, immediately record content, stable business identifiers or locations, owning container, UI state, and evidence paths. Capture virtual-list items before they leave the DOM; reused DOM nodes, identical text, or a final snapshot do not replace an accumulated inventory. Stop only after relevant containers reach their ends and continued observation reveals no new content. Unchanged document height alone is not a completion criterion. Compare page-provided totals or page counts with collected content. Default to at most 30 viewport scrolls per container. On reaching the limit, encountering infinite lists, failing to establish the end, or finding count mismatches, record visited scope and missing content, mark the result `partial`, and do not claim full coverage.
3. Save the current Markdown snapshot with `playwright-cli -s=<session> snapshot --filename <evidence-directory>/page.md`; confirm file existence before returning. Use accumulated inventories, segmented snapshots, and screenshots for historical virtual-list and interaction-state content. Do not label the final snapshot complete. Temporary evidence need not be deleted.
4. Use `playwright-cli -s=<session> run-code '<asynchronous Playwright page script>'` to build and accumulate a source-content inventory across viewports and UI states, covering at least:
   - Headings, paragraphs, lists, tables, links, code blocks, quotations, and rich-text editors.
   - `img`, `picture`, `svg`, `canvas`, `video[poster]`, `[role="img"]`, and CSS `background-image`.
   - Collapsible sections, tabs, pagination, dialogs, and selected, checked, disabled, expanded, or read-only control states.
   - `del`, `s`, `strike`, `mark`, `strong`, `b`, `em`, `i`, `u`, superscripts, subscripts, badges, and status labels.
   - Key computed styles of visible text nodes: `color`, `backgroundColor`, `textDecorationLine`, `fontWeight`, `fontStyle`, and `opacity`; also inspect visible text or status symbols in `::before` and `::after`.
5. For every visual candidate, record DOM order, nearby heading or text, type, alt/title/ARIA, resource URL, loading state, visibility, and dimensions. Classify as follows:
   - Content-bearing: conveys text, numbers, legends, relationships, flows, tables, page states, product interfaces, illustrations, or other business information not fully expressed in the body text. Extract visible text, subjects, data, spatial relationships, flow direction, legends/annotations, state, and context item by item.
   - Decorative: cross-verification through DOM metadata, context, and screenshots confirms only branding, separators, textures, or repeated icons with no independent business information. Summarize by type, count, and page region.
   - Unresolved: information-bearing status cannot be reliably determined, or resources are unloaded, obscured, too small, or blurred. Preserve candidate metadata, screenshot evidence, and the reason for uncertainty.
   `alt=""`, `aria-hidden`, CSS backgrounds, and proximity to text are only clues; none alone proves an image decorative.
6. Save a full-page screenshot with `playwright-cli -s=<session> screenshot --full-page --filename <evidence-directory>/page.png`; it does not cover all internal-scroll or virtual-list content. For content-bearing or unresolved images, SVGs, canvases, charts, screenshot tables, and key rich-text areas unreadable in the full-page image, save uniquely numbered local screenshots and analyze each. Capture necessary virtual-item evidence before items leave the viewport. If screenshots fail, capture adjacent containers or individual viewports and record the failure reason.
7. For collapsible sections, tabs, and pagination, perform only non-destructive expansion, switching, or scrolling. Do not submit forms or trigger business writes. Refresh relevant snapshots, DOM information, and necessary screenshots after switching, and label the corresponding UI state in the inventory.
8. Before summarizing, reconcile coverage: discovered counts for page structure items, all visual candidates, content-bearing visuals, rich-text marks, and interaction states must each satisfy the coverage equations. Decorative items count as analyzed only after cross-classification and inclusion in the summary. Continue verification if counts do not reconcile; do not return success directly.
9. Produce a Chinese summary in the caller's format or the default below. Explicitly preserve semantics lost by ordinary Markdown: render strikethrough as `~~原文~~（原页面删除线）` and other styles as `「原文」〔红色 #RRGGBB / 高亮 / 下划线 / 禁用等〕`. Preserve all overlapping styles on the same text.
10. Finish with `playwright-cli -s=<session> close` to close this task's browser. Do not call `close-all`, `kill-all`, `delete-data`, or any browser-state saving tool.

The default storage state initializes the browser. Never read, output, verify, analyze, or save state-file contents. Do not return the state-file path, cookies, origins, or other browser-state details.

## Return format

Use the following default structured result unless the caller overrides it. Fill business-facing values in Chinese; preserve the fixed Chinese field names.

```json
{
  "status": "success | partial | error",
  "title": "<page title>",
  "url": "<final URL>",
  "snapshot_path": "<absolute path to the acquired page Markdown snapshot, or empty>",
  "content_inventory_path": "<absolute path to accumulated inventory with scroll and UI-state records, or empty>",
  "screenshot_paths": ["<absolute path to a full-page or local screenshot>"],
  "summary": {
    "页面类型": "<page type>",
    "核心内容": "<core content>",
    "关键信息": "<key information>",
    "页面结构": "<page structure>",
    "图片与视觉内容": [
      {
        "位置": "<nearby heading, region, or control>",
        "类型": "<image, chart, SVG, Canvas, background, or other>",
        "分类": "<content-bearing or unresolved>",
        "资源信息": {"url":"<resource URL or none>","alt":"<original value or none>","title":"<original value or none>","aria":"<original value or none>","加载状态":"<loaded, unloaded, broken, or unknown>"},
        "内容": "<subject, visible text, data, relationships, flow, legends, annotations, state, and business information>",
        "证据": "<DOM, alt, screenshot, or cross-checked sources>",
        "截图路径": "<corresponding local or full-page screenshot path>",
        "置信度": "<high, medium, or low>"
      }
    ],
    "装饰型视觉资源汇总": [
      {
        "类型": "<branding, separator, texture, repeated icon, or other>",
        "数量": 0,
        "页面区域": "<page region>",
        "判定依据": "<DOM metadata, context, and screenshot evidence>"
      }
    ],
    "富文本与状态语义": [
      {
        "原文": "<exact text>",
        "样式或状态": ["<red #RRGGBB, strikethrough, highlight, disabled, selected, or other>"],
        "上下文": "<nearby heading, sentence, or control>",
        "页面明确含义": "<meaning explicitly explained by the page, otherwise 未说明>"
      }
    ],
    "交互与控件状态": ["<interaction and control states>"],
    "未确认内容": ["<location, medium, attempted methods, and unresolved scope>"]
  },
  "coverage": {
    "discovery_complete": false,
    "visited_scope": ["<visited pages, containers, pagination, and tabs>"],
    "unvisited_scope": ["<unvisited scope and stop reasons>"],
    "source_items": 0,
    "source_items_analyzed": 0,
    "source_items_unresolved": 0,
    "visual_items_found": 0,
    "visual_items_analyzed": 0,
    "visual_items_unresolved": 0,
    "content_visual_items_found": 0,
    "content_visual_items_analyzed": 0,
    "content_visual_items_unresolved": 0,
    "decorative_visual_items_found": 0,
    "unclassified_visual_items": 0,
    "rich_text_marks_found": 0,
    "rich_text_marks_analyzed": 0,
    "rich_text_marks_unresolved": 0,
    "interactive_states_found": 0,
    "interactive_states_analyzed": 0,
    "interactive_states_unresolved": 0
  }
}
```

Visual coverage must satisfy: `content_visual_items_found = content_visual_items_analyzed + content_visual_items_unresolved`; `visual_items_found = content_visual_items_found + decorative_visual_items_found + unclassified_visual_items`; `visual_items_analyzed = content_visual_items_analyzed + decorative_visual_items_found`; `visual_items_unresolved = content_visual_items_unresolved + unclassified_visual_items`.

Other coverage must satisfy: `source_items = source_items_analyzed + source_items_unresolved`; `rich_text_marks_found = rich_text_marks_analyzed + rich_text_marks_unresolved`; `interactive_states_found = interactive_states_analyzed + interactive_states_unresolved`. Reconcile item by item against a source inventory with locations or stable identifiers. Do not also count unresolved items as analyzed; reconciled statistics do not imply every item's content is identifiable.

Return `error` if the page cannot be retrieved, required evidence cannot be obtained, or inventory counts cannot be reconciled; preserve acquired evidence and failure reasons. Return `partial` when counts reconcile but discovery scope is incomplete; state stop reasons, visited and unvisited scope, and set `discovery_complete` to false. Return `success` only when containers, pagination, and tabs in the specified scope have been traversed, discovery is complete, and every item has analysis or a specific unresolved record. Still list unresolved items' locations, attempted methods, and missing scope; do not equate reconciled statistics with fully recognized content.
