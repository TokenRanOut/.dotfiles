---
name: skill-writing-guide
description: >
  Use this skill when the user asks you to create, improve, or evaluate a
  skill — including writing SKILL.md, optimizing the description field,
  adding scripts/, setting up evals, or reviewing an existing skill. Also
  use it when the user says "编写/优化/改进 skill" or mentions "skill
  writing guide". Do NOT use for: general code tasks unrelated to skill
  authoring, or for editing opencode config files (delegate to
  customize-opencode instead). 适用：用户要求编写、改进、优化或评估
  skill；添加 scripts/references/evals 等附属文件。不适用：与 skill
  编写无关的代码任务或 opencode 配置文件编辑（后者交给 customize-opencode）。
tags: skill,meta,creation,best-practices
---

# skill-writing-guide

## 适用场景

- 用户要求**创建新的 skill**
- 用户要求**改进/优化现有 skill**（评估、迭代）
- 用户要求**优化 skill 的 description** 以提高触发准确率
- 用户要求**为 skill 添加附属脚本**（`scripts/`）
- 用户提到 "skill writing guide" 或 "怎么编写 skill"

## 核心原则

1. **从真实经验出发** — 禁止 LLM 凭空生成 skill。必须基于现有项目约定、实际工作流程、或用户提供的具体上下文来编写。
2. **只写 agent 不知道的** — 不教基础概念（如 HTTP、PDF、Python），只写项目特有的约定、领域知识、非显而易见的坑点。
3. **设计内聚单元** — 一个 skill 做一件事。过窄则需多个 skill 协同加载，过宽则难精准触发。
4. **渐进式披露** — SKILL.md 正文 ≤500 行 / ≤5000 tokens，详细参考内容放到 `references/` 下，正文写明何时加载。
5. **实测迭代** — 第一版很少完美。跑真实任务 → 读执行轨迹 → 修正 → 再测。
6. **匹配控制粒度** — 容错任务给自由度（解释 why），危险/精确操作严格限定（精确命令，禁止修改）。

## 工作流程

进度：
- [ ] Step 1: 分析需求 — 确认 skill 范围和类型
- [ ] Step 2: 编写 SKILL.md — YAML 元数据 + 正文
- [ ] Step 3: 编写附属文件 — scripts/、references/、evals/（按需）
- [ ] Step 4: 自检 — 对照下方的禁止行为和 Gotchas 逐项核验
- [ ] Step 5: 实测 — 跑一个真实任务验证 skill 是否有效

## Gotchas

以下是编写 skill 时最容易踩的坑，agent 不加说明就会出错：

- **description 是路由而非文档** — agent 启动时**只看 description**，不读 SKILL.md 正文。description 写不好，skill 永远不会被触发。
- **skills 共享上下文窗口** — 加载的每个 skill 都在争夺有限的 context 空间。冗余内容不只是浪费，它会挤压其他 skill 和有价值的对话历史。
- **description 要偏"推"** — 即使用户不提关键词也应触发（如 "even if they don't explicitly mention 'CSV'"）。宁可宽一点被触发后正文澄清，也不因太窄而错过。
- **嵌套代码块易出错** — 在 SKILL.md 中展示"如何写 SKILL.md 里的代码块"时，Markdown 的三反引号嵌套会断裂。用缩进或四反引号替代。
- **正文和 references 重复是隐藏成本** — agent 加载 SKILL.md 后若读到与 references 相同的内容，浪费了上下文窗口。正文应只说"存在什么、何时加载"，细节留在 references。
- **禁忌叠加** — 如果两个 skill 的指令冲突（如一个要求 "总是做 X"，另一个要求 "永远不做 X"），agent 行为不可预测。依赖声明和分工边界必须清晰。

## 目录结构

```
skill-name/                    # kebab-case，与 YAML name 一致
├── SKILL.md                   # 核心文件（必须），YAML front matter + Markdown
├── scripts/                   # 可选：附属可执行脚本
├── references/                # 可选：详细参考文档（渐进披露）
├── evals/                     # 可选：评估用测试用例
│   ├── evals.json
│   └── files/                 # 测试输入文件
├── assets/                    # 可选：输出模板等资源文件
└── LICENSE.txt                # 可选：许可证
```

目录名、YAML `name`、SKILL.md 一级标题三者必须一致，使用 kebab-case。

## SKILL.md 元数据（YAML front matter）

### 必填字段

```yaml
name: skill-name               # kebab-case，与目录名一致
description: >
  Use this skill when ... Do NOT use for: ...
  适用：...。不适用：...。
```

### 可选字段

```yaml
tags: skill,meta,creation      # 逗号分隔，用于分类
license: Apache 2.0            # 许可证说明
compatibility: python>=3.10    # 运行环境要求
```

### Description 编写要点

以**英文祈使句**开头（"Use this skill when..."），中英双语，≤1024 字符。

| 准则 | 说明 |
|------|------|
| 祈使句式 | "Use this skill when..." 而非 "This skill does..." |
| 专注用户意图 | 描述用户想达成什么，而非 skill 内部做了什么 |
| 主动列出触发场景 | 即使用户没说关键词也应触发 |
| 用近义词做负面测试 | 最强的 "不应触发" 是概念接近但需求不同的 case |

完整优化指南（eval 脚本、train/validation 拆分、优化循环）见 **`references/description-optimization.md`** — 当 description 触发率不理想时读取。

## SKILL.md 正文章节指南

### 推荐章节

| 章节 | 何时使用 | 说明 |
|------|---------|------|
| `## 适用场景` | 始终 | 本 skill 的具体触发条件（比 description 更细） |
| `## 核心原则` | 始终 | Agent 必须遵守的 3-6 条行为准则，编号列出 |
| `## 工作流程 / 执行入口` | 始终 | Checklist 格式，告诉 agent 加载 skill 后第一步做什么 |
| `## Gotchas` | 始终 | 反直觉的坑点：命名不一致、软删除、端点行为差异等 |
| `## 可用命令 / 脚本` | 有脚本时 | 列出 `scripts/` 下的脚本及简要说明 |
| `## 输出要求` | 有输出时 | 输出格式模板（比散文描述更可靠） |
| `## 禁止行为` | 始终 | ❌ 标记，列出 agent 不得做的事 |
| `## 示例` | 有帮助时 | 调用示例或输入输出示例 |

### 常用模式

**Checklist** — 多步骤工作流使用 checklist 帮助 agent 追踪进度：

```markdown
进度：
- [ ] Step 1: 分析需求
- [ ] Step 2: 生成方案
- [ ] Step 3: 验证方案
- [ ] Step 4: 执行
- [ ] Step 5: 验证输出
```

**验证循环** — 关键步骤加入自检：执行 → 运行校验 → 失败则修复 → 重试直到通过。

**Plan-Validate-Execute** — 批量或破坏性操作：先生成中间计划 → 校验计划 → 再执行。

## 控制粒度校准

| 任务特征 | 策略 | 示例 |
|---------|------|------|
| 多方案可行，容错 | 给自由度，解释 why | "检查 SQL 注入，用参数化查询" |
| 精确序列，危险操作 | 严格限定，精确命令 | "只运行 `python migrate.py --verify --backup`，不修改命令" |

- **给默认方案而非菜单** — 多个工具可用时选一个默认推荐，简要提备选
- **教方法而非给答案** — 写流程而非写死具体数据

## scripts/ 脚本规范

脚本引用使用**相对路径**（以 skill 目录根为基准）。完整的设计模板（各语言自包含脚本、10 条 agent 友好设计原则）见 **`references/script-design.md`** — 当需要创建 `scripts/` 时读取。

最低要求速查：

- 禁止交互式提示（TTY prompt），输入全部通过 CLI 参数
- 必须有 `--help`，错误信息说清 "什么错了 + 期望什么 + 如何修正"
- stdout = 数据（结构化），stderr = 诊断
- 幂等性优先，"不存在则创建" 而非 "创建失败则报错"
- 外部工具固定版本：`uvx ruff@0.8.0 check .`

## Skill 类型模式参考

选择原则：先看是否有外部 CLI 工具可用（→ CLI 工具型），再看是否自带脚本依赖（→ 脚本驱动型），纯规则指导（→ 纯规则型），侧重美学/原则（→ 风格指南型），需叠加在其他 skill 上（→ 复合依赖型）。

| 类型 | 特征 | 适用场景 | 示例 |
|------|------|---------|------|
| **纯规则型** | 仅 SKILL.md，定义分工和规则 | 需要定义流程、规范、分工 | code-explore |
| **CLI 工具型** | 通过外部命令交互 | 已有 CLI 工具，skill 只是使用指引 | obsidian-vault |
| **脚本驱动型** | 附带 `scripts/` + `lib/` 依赖 | 需要自定义处理逻辑 | quick-render-uml |
| **风格指南型** | 侧重美学/原则指导，而非流程 | 视觉设计、写作风格等非确定性任务 | frontend-design |
| **复合依赖型** | 依赖其他 skill，叠加领域维度 | 在通用规则上增加领域特化 | trace-spring-api-chain |

## 技能评估与迭代

评估 skill 的核心方法是 **双跑对比**：每个测试用例跑两遍（有 skill + 无 skill 基线），用断言和人类复查双重判定。

完整框架（workspace 布局、grading 模板、benchmark 聚合、迭代循环）见 **`references/eval-framework.md`** — 当需要为 skill 建立正式评估体系时读取。

断言设计要点：
- ✅ "输出是合法 JSON"（可程序验证） / "图表展示 3 个月份"（可数、具体）
- ❌ "输出不错"（无法判定） / "包含精确短语 'Total Revenue: $X'"（太脆弱）

## 本地约定速查

- **符号约定** — ❌ 标记禁止行为，！！标记极其重要的提示
- **代码引用格式** — `ClassName.methodName() @ File:行号`
- **中英混排** — 中文和英文/数字之间加空格
- **依赖声明** — `！！开始前必须先加载 xxx skill`
- **语言** — 正文以中文为主体，关键术语中英对照
- **嵌套代码块** — 在 SKILL.md 中展示"含代码块的代码块"时，外层用四反引号 ```` ``` ```` 或缩进

## references/ 参考文件

> 引用文件时必须指明**何时加载**，而非笼统的 "see references/"。

- **`references/description-optimization.md`** — Description eval 脚本、train/validation 拆分、5 轮优化循环。当 description 触发率不理想时读取。
- **`references/eval-framework.md`** — Eval workspace 布局、断言 grading 模板、benchmark 聚合脚本、完整迭代循环。当需要为 skill 建立正式评估体系时读取。
- **`references/script-design.md`** — 各语言自包含脚本模板（Python PEP 723、Deno、Bun、Ruby）、10 条 agent 友好设计原则、`--help` 输出规范。当为 skill 添加 `scripts/` 时读取。

## 禁止行为

- ❌ LLM 凭空生成 skill（没有真实上下文支撑）
- ❌ 教 agent 基础概念（HTTP、Python 语法、PDF 是什么）
- ❌ SKILL.md 正文超过 500 行 — 应拆分到 `references/`
- ❌ description 写得过于模糊（如 "处理数据"）或只描述功能不描述用户意图
- ❌ description 缺少英文部分、缺 "Do NOT use for" 部分、或用非祈使句式
- ❌ description 只写功能清单（"覆盖 X、Y、Z"），不写 "Use this skill when..."
- ❌ 脚本出现交互式提示（`input()`、密码对话框等）
- ❌ skill 目录名、YAML name、H1 标题三者不一致
- ❌ 引用文件时不说明"何时加载"
- ❌ 正文与 references 大量重复 — 浪费上下文窗口
