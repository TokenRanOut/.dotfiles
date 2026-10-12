# Description Optimization Guide

## 何时读取本文件

当需要系统性减少 skill 的误触发和漏触发时读取。小范围措辞修改可只走查代表性正负场景，无需启动完整优化循环。

## 工作原理

技能目录中的 `name` 和 `description` 用于加载前的路由；正文提供执行细节。description 应说明用户目标和适用边界，而不是复述整套流程。

按任务意图与技能范围判断是否应触发，不以关键词重合、任务难度或“超出模型能力”作为替代条件。语言、句式及是否双语由目标用户和环境决定。

## Eval 查询设计

### 文件格式 (`evals/trigger_queries.json`)

```json
[
  { "query": "用户提示语...", "should_trigger": true },
  { "query": "另一个提示语...", "should_trigger": false }
]
```

用例数量按任务规模选择；正式优化可从约 20 个查询起步，兼顾应触发与不应触发。若不足以形成独立数据集，就将结果标为场景走查，不声称已验证泛化。

### Should-trigger 查询（正面测试）

沿以下维度变化：

- **措辞** — 正式/随意/拼写错误/缩写
- **显式度** — 有的直接提领域关键词，有的只描述需求不提名称
- **详细度** — 简洁版和上下文丰富的版本混合
- **复杂度** — 单步任务 + 多步工作流混合

正面查询须确实属于技能范围；优先包含意图明确但没有领域关键词的表达，而非仅仅“可能有帮助”的任务。

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

模型行为是非确定性的。可预先约定触发率 ≥0.5 判为“触发”，然后与 `should_trigger` 比较；负例触发率高是失败。分别报告漏触发与误触发，不只追求触发率。脚本是适配示例，需核验当前客户端及日志结构；命令或解析失败应报告为运行错误，不能计作未触发。

## 避免过拟合：开发集与独立最终测试集

在调优前固定拆分，并避免同一场景的近似改写跨集合泄漏：

- **Train 集**：分析错误、指导修改。
- **Validation 集（可选）**：用于开发期间比较候选和选优；只要参与选优，就属于调优数据，不能当作独立泛化证据。
- **Final test 集**：独立保留，调优和选优期间不查看查询、错误或得分；冻结最终版本后只运行一次，用于最终报告。

各集均覆盖正负例及相邻意图。数据较少时可只使用开发集和独立最终测试集，不机械套用比例。预先约定评价指标和停止条件。

## 优化循环

```
1. 在 train 集上评估当前 description
2. 在 train 集中识别失败：
   - should-trigger 未触发 → description 可能太窄
   - should-not-trigger 误触发 → description 可能太宽
3. 改进 description：
   - 避免直接加入失败查询中的关键词（过拟合）
   - 找这些查询代表的**通用类别或概念**来修正
   - 卡壳时尝试结构性改写而非增量微调
    - 遵守目标平台的 description 长度限制
4. 在约定预算内重复 1-3；不为追求 train 全过无限添加关键词
5. 如设 validation，用预先约定的指标选优；否则依据开发集与人工复核冻结版本
6. 对冻结版本运行独立 final test，报告正负例结果；不得据此继续选版本并仍称其独立测试
```

迭代预算按任务规模设置；无改善时检查范围、标签、措辞歧义和实际执行轨迹。若依据最终测试反馈继续修改，该集合即成为开发数据，下一轮需新的独立最终测试集。

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
2. 检查 frontmatter 和目标平台长度限制
3. 记录开发集与可选 validation 的选择过程，不把它们当最终测试
4. 对冻结版本运行事先保留的独立最终测试集；报告误触发、漏触发和样本规模限制
