# Description Optimization Guide

## 何时读取本文件

当你需要系统性优化 skill 的 `description` 字段以提高触发率时读取。

## 工作原理

Agent 启动时只加载每个 skill 的 `name` 和 `description`。当用户任务匹配 description 时，agent 才读取完整 SKILL.md。因此 description 承载了全部触发责任。

关键细节：agent 通常只在任务需要**超出自身能力范围的知识**时才查询 skill。简单的单步请求（如 "读取这个 PDF"）可能不会触发 PDF skill，因为 agent 用基础工具就能处理。

## Eval 查询设计

### 文件格式 (`evals/trigger_queries.json`)

```json
[
  { "query": "用户提示语...", "should_trigger": true },
  { "query": "另一个提示语...", "should_trigger": false }
]
```

至少准备 20 个查询：8-10 个应触发 + 8-10 个不应触发。

### Should-trigger 查询（正面测试）

沿以下维度变化：

- **措辞** — 正式/随意/拼写错误/缩写
- **显式度** — 有的直接提领域关键词，有的只描述需求不提名称
- **详细度** — 简洁版和上下文丰富的版本混合
- **复杂度** — 单步任务 + 多步工作流混合

最有价值的正面查询是 **skill 有帮助但查询本身不明显** 的 case —— 这些最能检验 description 质量。

### Should-not-trigger 查询（负面测试）

最有价值的负面测试是 **近义词** —— 与 skill 共享关键词或概念但实际需求不同的查询：

- ✅ 强负面：`"我需要更新 Excel 预算模板里的公式"` — 共享 "表格/数据" 概念，但不需数据分析
- ❌ 弱负面：`"写一段斐波那契函数"` — 明显无关，测不出什么

### 真实感提示语要素

- 文件路径：`~/Downloads/report_final_v2.xlsx`
- 个人上下文：`"我老板让我..."`
- 具体细节：列名、公司名、具体数值
- 口语化表达、缩写、偶尔拼写错误

## 测试脚本

基本思路：每个查询跑多次（建议 3 次），计算触发率。

```bash
#!/bin/bash
QUERIES_FILE="${1:?Usage: $0 <queries.json>}"
SKILL_NAME="my-skill"
RUNS=3

check_triggered() {
  local query="$1"
  # 替换为实际 agent client 的触发检测逻辑
  # 返回 0 = 触发成功，1 = 未触发
  claude -p "$query" --output-format json 2>/dev/null \
    | jq -e --arg skill "$SKILL_NAME" \
      '.messages[].content[] | select(.type == "tool_use" and .name == "Skill" and .input.skill == $skill)' \
      > /dev/null 2>&1
}

count=$(jq length "$QUERIES_FILE")
for i in $(seq 0 $((count - 1))); do
  query=$(jq -r ".[$i].query" "$QUERIES_FILE")
  should_trigger=$(jq -r ".[$i].should_trigger" "$QUERIES_FILE")
  triggers=0

  for run in $(seq 1 $RUNS); do
    check_triggered "$query" && triggers=$((triggers + 1))
  done

  jq -n \
    --arg query "$query" \
    --argjson should_trigger "$should_trigger" \
    --argjson triggers "$triggers" \
    --argjson runs "$RUNS" \
    '{query: $query, should_trigger: $should_trigger, triggers: $triggers, runs: $runs, trigger_rate: ($triggers / $runs)}'
done | jq -s '.'
```

模型行为是非确定性的 —— 同一条查询可能一次触发一次不触发。阈值 ≥0.5 可视为通过。

## 避免过拟合：Train/Validation 拆分

将查询集按 ~60/40 分割：

- **Train 集**：用于发现问题和指导改进
- **Validation 集**：仅用于检查改进是否泛化

确保两集都包含 proportion 相当的 should-trigger 和 should-not-trigger。随机打乱后固定拆分，跨迭代保持对比一致。

## 优化循环

```
1. 在 train + validation 集上评估当前 description
2. 在 train 集中识别失败：
   - should-trigger 未触发 → description 可能太窄
   - should-not-trigger 误触发 → description 可能太宽
3. 改进 description：
   - 避免直接加入失败查询中的关键词（过拟合）
   - 找这些查询代表的**通用类别或概念**来修正
   - 卡壳时尝试结构性改写而非增量微调
   - 确保不超过 1024 字符
4. 重复 1-3 直到 train 全过或不再改善
5. 选 validation pass rate 最高的版本（不一定是最新版本）
```

5 轮迭代通常足够。如果无法改善，可能是查询本身有问题（太简单/太难/标签错误）。

## 改进示例

```yaml
# Before — 太模糊
description: Process CSV files.

# After — 具体 + 触发场景
description: >
  Analyze CSV and tabular data files — compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use this
  skill when the user has a CSV, TSV, or Excel file and wants to
  explore, transform, or visualize the data, even if they don't
  explicitly mention "CSV" or "analysis."
```

## 收尾验证

1. 更新 `SKILL.md` 的 `description` 字段
2. 确认不超过 1024 字符
3. 手动试几个 prompt 做快速检查
4. 写 5-10 条全新查询（混合正负），跑一遍 eval —— 这些查询从未参与优化，能诚实检验泛化能力
