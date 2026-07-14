# Eval Framework Reference

## 何时读取本文件

当需要为 skill 设置完整的评估体系（设计 test case、搭建 workspace、grading、benchmark 聚合）时读取。

## 测试用例设计 (`evals/evals.json`)

每个 test case 有三部分：

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "I have a CSV of monthly sales data in data/sales_2025.csv. Can you find the top 3 months by revenue and make a bar chart?",
      "expected_output": "A bar chart image showing the top 3 months by revenue, with labeled axes and values.",
      "files": ["evals/files/sales_2025.csv"],
      "assertions": [
        "The output includes a bar chart image file",
        "The chart shows exactly 3 months",
        "Both axes are labeled",
        "The chart title or caption mentions revenue"
      ]
    }
  ]
}
```

### 提示语设计技巧

- **从 2-3 个 test case 开始** — 别在见到第一轮结果前过度投入
- **变化措辞** — 随意 / 精确混合
- **覆盖边界** — 至少一个测试边界条件（格式错误的输入、异常请求、skill 指令可能模糊的 case）
- **真实上下文** — 加上文件路径、列名、个人背景

## Workspace 结构

```
skill-name-workspace/
└── iteration-1/
    ├── eval-top-months-chart/
    │   ├── with_skill/
    │   │   ├── outputs/          # 实际输出文件
    │   │   ├── timing.json       # token 数 + 时长
    │   │   └── grading.json      # 断言判定结果
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    ├── eval-clean-missing-emails/
    │   ├── with_skill/
    │   └── without_skill/
    └── benchmark.json            # 汇总统计
```

## 运行 Eval

每次运行必须**上下文干净** —— 没有先前运行的残留状态。用 subagent 或独立 session。

每个 test case 跑两次，分别指定 skill 路径（或不指定做基线对比）：

```
执行此任务：
- Skill path: /path/to/my-skill
- Task: <eval prompt>
- Input files: evals/files/xxx.csv
- Save outputs to: <workspace>/iteration-N/eval-xxx/with_skill/outputs/
```

### Timing 数据

运行完成后记录：

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332
}
```

## 断言设计

在见到第一轮输出后添加断言 —— 你通常不知道"好"是什么样直到 skill 跑过。

### 好的断言

- `"输出文件是合法 JSON"` — 可程序验证
- `"柱状图有标注坐标轴"` — 具体可观察
- `"报告至少包含 3 条建议"` — 可数

### 差的断言

- `"输出不错"` — 无法判定
- `"输出包含精确短语'Total Revenue: $X'"` — 太脆弱，正确但措辞不同的输出也会失败

### 断言适用范围

并非所有质量维度都适合断言。写作风格、视觉设计、输出"感觉对不对" —— 这些只能靠**人类复查**捕捉。断言留给可客观检验的内容。

## Grading 输出

对每条断言给出 **PASS** 或 **FAIL**，附带具体证据（引用或描述输出内容，而非意见）。

```json
{
  "assertion_results": [
    {
      "text": "The output includes a bar chart image file",
      "passed": true,
      "evidence": "Found chart.png (45KB) in outputs directory"
    },
    {
      "text": "Both axes are labeled",
      "passed": false,
      "evidence": "Y-axis labeled 'Revenue ($)' but X-axis has no label"
    }
  ],
  "summary": {
    "passed": 3,
    "failed": 1,
    "total": 4,
    "pass_rate": 0.75
  }
}
```

### Grading 原则

- **PASS 需要具体证据** — 不要给怀疑的余地。断言说"包含摘要"但输出只有一个标着"Summary"的模糊句子 → FAIL
- **复审断言本身** — 太容易（始终 PASS 无论 skill 质量）、太难（始终 FAIL 即使输出好）、或不可验证（无法从输出判定）都要修正

### 盲比（可选）

如果比较两个 skill 版本，做**盲比**：将两份输出交给 LLM 评判但不标注哪个是哪个版本。评判者按自己的 rubric 给组织、格式、可用性、精致度等整体质量维度打分。这补充了断言评级 —— 两份输出可能都通过了所有断言但整体质量差异显著。

## Benchmark 聚合

```json
{
  "run_summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83, "stddev": 0.06 },
      "time_seconds": { "mean": 45.0, "stddev": 12.0 },
      "tokens": { "mean": 3800, "stddev": 400 }
    },
    "without_skill": {
      "pass_rate": { "mean": 0.33, "stddev": 0.10 },
      "time_seconds": { "mean": 32.0, "stddev": 8.0 },
      "tokens": { "mean": 2100, "stddev": 300 }
    },
    "delta": {
      "pass_rate": 0.50,
      "time_seconds": 13.0,
      "tokens": 1700
    }
  }
}
```

delta 告诉你 skill 成本（更多时间、更多 token）和收益（更高 pass rate）。+13 秒换 +50 百分点 pass rate 值；翻倍 token 换 +2 百分点不值。

## 模式分析

汇总统计后，深入分析：

- **移除两方都始终 PASS 的断言** — 不提供有效信息，模型无 skill 也能处理
- **调查两方都始终 FAIL 的断言** — 要么断言坏了、test case 太难、要么查错了东西
- **重点研究 skill PASS 而基线 FAIL 的断言** — 这是 skill 真正在增加价值的地方，理解为什么
- **结果在各次运行间不稳定的 case**（高 stddev）→ skill 指令可能模糊，加示例或更具体指引
- **检查时间/token 异常值** — 某条 eval 耗时 3 倍 → 读执行轨迹找瓶颈

## 人类复查

断言评分和模式分析能发现很多，但只能检查你预设了断言的东西。人类复查能捕捉意外问题。

对每个 test case 审查实际输出 + 评分，记录具体反馈：

```json
{
  "eval-top-months-chart": "图表缺坐标轴标签，月份按字母序排列而非时间序。",
  "eval-clean-missing-emails": ""
}
```

"图表缺坐标轴标签" 可操作；"看起来不对" 不可操作。空字符串 = 输出没问题。

## 迭代循环

迭代时把三种信号汇总：

1. **失败断言** → 具体缺口（缺失步骤、模糊指令、skill 未覆盖的 case）
2. **人类反馈** → 更广泛的质量问题（方法错了、输出结构差、技术正确但无用）
3. **执行轨迹** → 问题根因（agent 忽略指令 = 指令模糊；浪费时间 = 可删的指令）

将三者 + 当前 SKILL.md 交给 LLM 生成改进建议时，给以下指引：

- **从反馈中泛化** — 修复要覆盖根本原因而非单点打补丁
- **保持精简** — 更少更好的指令通常优于穷举规则。如果 pass rate 随加规则而停滞，试试删除指令看结果是否维持
- **解释 why** — "因为 X 通常导致 Y 所以做 Z" 比 "ALWAYS do X, NEVER do Y" 更可靠
- **打包重复工作** — 如果每次运行都独立写了相似脚本 → 信号应打包进 `scripts/`

循环：
```
1. 将 eval 信号 + 当前 SKILL.md 给 LLM → 生成改进提案
2. 审核并应用修改
3. 重新跑全部 test case → 新 iteration-N+1/
4. Grade + 聚合
5. 人类复查
6. 重复直到满意或不再有意义改善
```
