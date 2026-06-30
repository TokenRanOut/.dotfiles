---
name: quick-render-uml
description: 适用：渲染 PlantUML 为图像并预览（时序图/类图/流程图等），从 .puml 文件、标准输入、剪贴板、自然语言描述生成 SVG/PNG。不适用：只讨论设计概念而不出图、非 PlantUML 格式图表。Use when: rendering PlantUML diagrams, previewing .puml files, generating SVG/PNG. Do NOT use: conceptual discussion only, non-PlantUML diagrams.
tags: uml,plantuml,svg,png,render,preview
---

# Quick Render UML

用于在本机快速把 PlantUML 渲染成 SVG 或 PNG，并自动通过 macOS `open` 预览。

## 适用场景
- 用户需要将 PlantUML 渲染为图像并预览（从 .puml 文件、标准输入、剪贴板、自然语言描述）
- 用户贴了一段 PlantUML 代码，希望直接看到图
- 用户描述了业务流程/设计，希望直接出图而非只返回代码

## 执行入口

优先在 skill 根目录下调用脚本，不要把渲染细节展开在正文里。

当用户目标是“得到一张 UML 图”时，优先使用本 skill 直接渲染。
如果用户只有自然语言描述，没有现成 `.puml` 或 PlantUML 代码，先生成最小可用的 PlantUML，再通过 `./bin/render-uml.sh stdin --name diagram` 直接渲染预览，而不是只停留在文本结果。
如果用户没有明确指定格式，默认输出并预览 `svg`；只有在用户明确要求 `png` 时才切换格式。

```bash
./bin/render-uml.sh doctor
./bin/render-uml.sh file doc/uml/recruit-order-sequence.puml
./bin/render-uml.sh file doc/uml/recruit-order-sequence.puml --png
./bin/render-uml.sh stdin --name diagram
./bin/render-uml.sh clipboard --name diagram
```

## 脚本约定
- 默认优先输出 `svg`
- 默认自动预览，使用 `open`
- 所有中间文件和输出文件都必须写入系统临时目录
- 优先使用 `lib/plantuml-*.jar`
- 本地 jar 不可用时，自动回退系统 `plantuml`
- 仅支持 `svg` 和 `png`

## 输出要求
- 告诉用户最终生成的临时文件路径
- 如果渲染失败，返回 PlantUML 原始报错

## 注意事项
- 当用户说"画 UML 图"时，优先直接产出并渲染图，而不是只解释怎么画
- 当用户未指定格式时，默认生成 `svg`，不要主动降级为 `png`；用户明确要求 `png` 时才切换
- 大多数场景下，已有 `.puml` 文件时应优先使用 `./bin/render-uml.sh file ...`
- 不要把渲染结果写回项目目录
- 如果用户明确不要自动预览，再追加 `--no-open`
- 不要在 skill 正文中写绝对路径
