---
tags:
  - 【Business domain】
  - 技术方案
date: 【YYYY-MM-DD】
---

# 【Requirement or requirement-item name】技术方案

> 需求来源：[需求原文](【Requirement body, URL, or document path】)
> 设计日期：【YYYY-MM-DD】

【Write the completed business document in Chinese. Keep its fixed Chinese headings and fields. Use paths relative to the owning repository root for source evidence, file locations, and proposed file targets; preserve the complete directory hierarchy and avoid local absolute paths. Identify projects for cross-repository references without repeating project prefixes when a project column exists. Include line numbers for existing code; never invent them for proposed files. This does not change document output or requirement-source path rules. Remove this prompt from the generated body.】

## 1. What

### 1.1 改什么

- 【Observable changes to business behavior or capabilities after implementation; omit implementation details here】

### 1.2 范围

- 涉及项目：【Projects】
- 修改内容：【Capabilities or modules】
- 不修改：【Necessary boundaries affecting implementation understanding; remove if absent】

### 1.3 待确认事项

【Keep this subsection only when unresolved questions exist.】

- 【Specific question; checked scope or unavailable verification prerequisites; reason it remains unresolved; missing information; specific implementation impact. Ask explicitly when a business decision is required.】

## 2. Why

【Explain why this change is needed using verified current facts and necessary constraints, without restating goals. Divide content with the table below to avoid repeating facts.】

| 现状事实 | 对本次修改的影响 | 代码证据 |
|---|---|---|
| 【Fact】 | 【Specific impact】 | `【Class.method() @ repository-relative-path:line】` |

## 3. How

【Group confirmed information by scenario, rule topic, and contract before choosing representations by content: Mermaid graph for overall flows, preferably text trees in text fences for local branches, short numbered steps for simple linear logic, target-language code as needed for precise mechanisms, and tables or code for fields and contracts. Follow the writing rules' topic-organization guidance for supplementary content. Keep one primary representation per piece of logic. Use only flowcharts for diagrams. Each chart covers one complete business flow starting independently at an explicit business entry; do not pile up implementation names or stitch charts together. Remove empty conditional subsections below and update numbering after additions or removals.】

### 3.1 处理流程

【Use flowcharts for cross-step collaboration, loops, or complex execution paths, independently covering the explicit business entry, key actions, necessary branches, and outcomes. Do not attach this chart's entry to another chart's end. Put local branches in core rules and implementation; keep only the corresponding business action and rule reference in the chart. Remove this subsection for simple scenarios when a rule tree alone establishes entry, processing, and result.】

#### 【Scenario name】

【Provide a complete scenario flowchart in a mermaid fence beginning with graph TD; (graph LR; for horizontal layout). Put each node/edge statement on its own line with a terminating semicolon. Use simple English node IDs, double-quoted Chinese labels, basic shapes and arrows, and no dependence on newer syntax, initialization directives, or HTML. Follow the writing rules for compatibility; do not call static syntax checks rendering validation. Simple linear logic may use short numbered steps instead; do not retain equivalent diagram and prose flows.】

【Label key executing capabilities as reused or proposed. Favor business meaning in chart labels. Keep useful executing-class mappings and references beside the chart: Class.method() @ existing-repository-relative-path:line; use target repository-relative paths for proposed capabilities. Complete missing flow conditions, execution order, and outcomes in the chart itself. Put independent rules and contracts in their owning topics and reference them here when needed.】

### 3.2 核心规则与实现

【Organize key decisions, data/state changes, and concrete mechanisms by rule topic without repeating overall steps. Prefer text trees for local branches, short statements for independent constraints, and code as needed for precise mechanisms; retaining both the tree and code below is not mandatory. Before code, establish owning layers/classes, method responsibilities, reused/new capabilities, dependency acquisition, and exception handling from project conventions, similar implementations, and applicable coding standards.】

#### 【Rule name】

【Use the following tree for a local decision. Name the decision subject or action at the root; give exact conditions and corresponding behavior on branches. Children apply only when the parent condition holds. State match priority separately when relevant; siblings do not imply execution order. Replace with short statements or code when a tree is unnecessary.】

```text
【Decision subject or processing action】
├─ 【Condition one】: 【Behavior or return result】
└─ 【Condition two】: 【Subject of further evaluation】
   ├─ 【Child condition one】: 【Behavior or data change】
   └─ 【Child condition two】: 【Behavior or return result】
```

【Identify key executing capabilities, reuse/proposed status, and source locations here. Complete conditions and behavior directly expressible in the tree within the tree itself. Keep only necessary definitions and precise mechanisms beside it; reference contracts already defined in their owning topics rather than repeating conditions, results, or equivalent pseudocode.】

【Keep the following code block only when key calls, algorithms, or precise operations need supplementing; delete it when the tree is sufficient. Follow production-code design standards and simplify only mechanical implementation.】

**`【Project / target repository-relative path / Class.method(signature)】`**

```java
【Use the target project's language and applicable project/coding-skill conventions; change the fence language accordingly. Show the entry, real reused calls, explicitly labeled additions, key branches, and data flow. Preserve necessary responsibility separation, dependency usage, exception behavior, call order, and outcome-affecting transaction boundaries.】
```

#### 辅助方法与规则

【Keep when proposed new business methods exist. Explain only implementation-essential contracts and logic omitted from the main flow. Do not hide key design behind method names or mechanically list private methods.】

```java
【ProposedMethodName(parameters with verified existing or explicitly proposed types)】 {
    // 【Key inputs/outputs and implementation-affecting business rules】
    【Key calls and processing logic】
}
```

【For proposed types, state their new status, responsibilities, target repository-relative paths, and key fields here or in the corresponding field table. Reference existing definitions without repeating them.】

### 3.3 接口

【Keep when interfaces change.】

#### `【METHOD /path or Interface.method(signature)】`

所属服务：`【Providing service name verified from code or configuration】`；所在项目/模块：`【Project / module】`

用途：【One sentence stating the business action performed by the call】

| 项目 | 内容 | 代码证据 |
|---|---|---|
| Provider | 【This change; remove the row if unchanged】 | `【Project / repository-relative-path:line / Class.method; omit line numbers for proposed files】` |
| Consumer | 【This change; remove the row if unchanged】 | `【Project / repository-relative-path:line / Class.method; omit line numbers for proposed files】` |
| 鉴权与身份 | 【Changed or implementation-essential existing token fields, permissions, or data scope; remove if irrelevant】 | `【Code location】` |
| 行为变化 | 【Specific added, modified, or deleted behavior】 | `【Code location; remove the row if no code location exists】` |

**处理规则**

1. 【One interface-specific decision or action; reference core rules and implementation for shared rules】

**请求字段**

【List all fields for new interfaces and differences for modified interfaces. Remove the table and explain when there are no request parameters.】

| 字段路径 | 参数位置 | 类型 | 是否必传 | 允许 null | 变化 | 说明及缺省行为 | 枚举/示例 |
|---|---|---|---|---|---|---|---|
| `【object.child.field】` | 【Path/query/header/body/form/RPC parameter/etc.】 | `【type】` | 【Yes/no】 | 【Yes/no/not applicable to transport】 | 【Add/modify/delete】 | 【Business meaning and omission behavior for optional fields】 | 【Value】 |

**响应字段**

【List all fields for new interfaces and differences for modified interfaces. Remove the table and explain when there are no response fields.】

| 字段路径 | 类型 | 是否必返 | 允许 null | 变化 | 说明及缺省行为 | 枚举/示例 |
|---|---|---|---|---|---|---|
| `【result.child.field】` | `【type】` | 【Yes/no】 | 【Yes/no/not applicable to transport】 | 【Add/modify/delete】 | 【Business meaning and omission behavior for optional fields】 | 【Value】 |

**请求示例**

【Show a complete call in its actual transport format. Replace the following JSON for JSON payloads; replace the fence and language for other forms. If there is no request body, state actual parameter locations rather than substituting an empty object. Modified-interface examples may include unchanged fields but not deleted ones.】

```json
{}
```

**响应示例**

【Show the complete post-change result consistent with the difference table. Replace the fence and language for non-JSON results; use actual status codes or observable results when no response body exists.】

```json
{}
```

**错误与兼容**

【Keep when applicable.】

- 【Error condition -> error code or caller behavior; explain the concrete impact of compatibility changes on existing callers】

【For whole-interface deletion, replace processing rules, fields, and normal examples with the original contract, replacement if any, and post-deletion call outcome. Retain applicable ownership and RPC dependency-version information.】

**RPC 依赖版本**

【Keep for public-contract additions, modifications, or deletions.】

| 项目 | 角色 | 依赖坐标 | 当前版本 | 目标版本 | 版本声明位置 |
|---|---|---|---|---|---|
| 【Project】 | 【Provider contract module/Consumer】 | `【groupId:artifactId】` | `【version】` | `【version】` | `【Build-file repository-relative path and property or dependency node】` |

### 3.4 数据、缓存与消息

【Keep categories according to actual changes.】

#### 数据库

【Fully define new tables; list differences and necessary existing constraints for modified tables. State database ownership across services or where names are ambiguous.】

| 表/字段 | 类型与约束 | 读写时机 | 具体 SQL 或索引 |
|---|---|---|---|
| `【table.column】` | 【Type, nullability, default, index】 | 【Condition】 | `【SQL/index】` |

```sql
【Complete SQL for additions or modifications; describe only, do not execute】
```

#### 缓存

【Fully define new cache-value structures; list differences and necessary existing constraints for modifications. Identify reading/writing services across services or where names are ambiguous.】

| Key | Value | TTL | 写入/覆盖/删除条件 | 读取与异常行为 |
|---|---|---:|---|---|
| `【Complete key template】` | `【Complete structure or type】` | 【Seconds】 | 【Exact conditions】 | 【Hit, miss, error】 |

#### 消息

| Topic/Queue | Producer / Consumer | 投递时机与失败行为 | 代码证据 |
|---|---|---|---|
| `【Name】` | 【Producing/consuming capabilities; identify services across services or where names are ambiguous】 | 【Specific semantics】 | `【Producer Class.method @ repository-relative-path:line; Consumer Class.method @ repository-relative-path:line; omit line numbers for proposed files】` |

**消息字段**

【List all fields for new messages and differences for modifications. Recursively expand objects and arrays to leaf fields.】

| 字段路径 | 类型 | 是否必传 | 允许 null | 变化 | 业务含义及缺省行为 | 枚举/示例 |
|---|---|---|---|---|---|---|
| `【object.child.field】` | `【type】` | 【Yes/no】 | 【Yes/no】 | 【Add/modify/delete】 | 【Specific meaning and omission behavior for optional fields】 | 【Value】 |

### 3.5 外部配置

【Keep when the configuration center changes.】

#### 【Configuration topic】

所属服务：`【Service reading and using the configuration】`

配置位置：【Actual configuration center and necessary namespace, group, configuration set, or other location details; include only applicable levels. Verify existing information and label proposed additions explicitly.】

| 配置键 | 变化 | 值类型 | 业务含义及取值约束 | 默认值与未配置行为 |
|---|---|---|---|---|
| `【Exact configuration key】` | 【Add/modify/delete】 | `【Type】` | 【Meaning, range/enums, applicable units】 | 【Code default; explicitly state when absent; handling when not configured】 |

【Fully define additions, list differences and necessary existing constraints for modifications, and explain business behavior after deletion. Recursively expand objects/arrays to leaves using full additions and modification differences, including required status, nullability, and omission behavior.】

- 空值与非法值：【Actual handling】
- 生效机制：【Startup reading, restart-required activation, or dynamic refresh; explain post-update scope for refresh, not merely configuration-center push support】
- 业务行为：【Reference the corresponding key's decisions and results in core rules without repeating them】

**配置示例**

【Provide complete relevant post-change configuration in the actual storage format and adjust the fence language. Identify proposed values without confusing them with code defaults. Exclude deleted items and unrelated configuration-set content. For deletion-only changes, explain post-deletion behavior instead.】

```text
【Configuration content directly usable or mergeable into the corresponding configuration set】
```

【Describe configuration-center changes completely here rather than substituting repository configuration-file changes or inventing repository paths. Add reading code or repository configuration files to the code-change table only if they actually change.】

### 3.6 代码改动

【List files changed by this requirement's complete final design, including changes already implemented or released. Do not narrow the table to current workspace differences or remaining work. Cite unchanged reused capabilities in flows or core implementation rather than this table.】

| 项目 | 变更 | 类/方法/字段 | 具体修改 | 仓库相对路径 |
|---|---|---|---|---|
| 【Project】 | 【Add/modify/delete】 | `【Symbol or signature】` | 【One sentence without repeating flows or implementation】 | `【Repository-relative path】` |

## 4. Example

### 4.1 正常示例

【Use concrete inputs through key processing and results to verify What goals; do not merely repeat interface payloads.】

1. 输入：【Concrete request or event】
2. 处理：【Key steps】
3. 数据：【Actually involved key fields, SQL results, or cache values; remove when there are no data changes】
4. 输出：【Complete response or observable result】

### 4.2 边界示例

【Keep only when necessary. Choose key conditions, errors, or boundaries with different results. For external configuration, use concrete values covering key business branches without repeating configuration definitions or shared normal-example processing.】

1. 输入：【Boundary or error condition】
2. 处理：【Specific branch】
3. 输出：【Error code, null value, or data state】
