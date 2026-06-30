---
name: code-explore
description: 通用代码探索规则，定义如何使用 subagent 读取归纳代码文件。适用：分析代码文件、阅读代码逻辑、探索代码库。不适用：非代码任务。Use when: analyzing source code, exploring codebases, reading code files. Do NOT use for: non-code tasks.
---

# code-explore

## 适用场景
- 任何需要读取并分析代码文件的任务
- 主 agent 需要理解代码逻辑但不膨胀上下文
- 多个代码文件需要并行分析

## 核心原则

1. **先理解再分析** — 不要假设项目结构，先探测再深入
2. **位置精确到三级** — 代码引用必须包含 `模块/类名.方法名()` 和 `文件名:行号`，缺一不可

## 分工边界

| 操作 | 执行者 | 说明 |
|------|--------|------|
| grep / glob 搜索定位文件 | 主 agent | 轻量操作，不膨胀上下文 |
| 读取并分析完整文件（>30行） | subagent (explore/general) | 主 agent 严禁直接 read |
| 拼接分析结论 | 主 agent | 基于 subagent 返回的摘要 |

## Subagent 摘要模板

每个 subagent 按以下格式返回结构化摘要：

```
## 文件: xxx
### 类/模块/结构体: XxxImpl
### 关键方法:
- methodName(Params): ReturnType @ 行号范围
  - 参数处理: 行号
  - 校验/检查: 行号，内容
  - 调用关系: calledMethod() -> 被调用类/模块名 @ 行号
  - 数据操作: 操作类型 @ 行号
  - 外部调用: 调用方式 @ 行号
  - 异常处理: 行号，类型
### 依赖/字段:
- fieldName: FieldType (@ 行号)
```

调用方可在 prompt 中追加领域/框架特有提取项（如事务、缓存、消息队列等），subagent 在模板末尾追加返回。

## 工作参数

- **type**: `explore` 或 `general`（subagent_type）
- **描述**: 3-5 个词的短描述，如 `read XxxService.java`
- **prompt**: 指定读取文件路径、需要提取的信息、返回摘要格式、包含行号
- **并行**: 同层级无依赖的多个文件同时 spawn subagent

## 禁止行为

- ❌ 主 agent 直接用 `read` 读取超过 30 行的代码文件
- ❌ 主 agent 自己去读文件分析代码逻辑
- ❌ 串行调用互无依赖的 subagent 任务

## 代码引用格式

代码位置引用精确到三级：模块/类名、方法名/函数名、行号。

- 单行：`ModuleName.methodName() @ FileName:行`
- 连续多行：`ModuleName.methodName() @ FileName:行-行`
- 同文件内跳转：上一行已标注类名时，可用 `行 → 行` 简写

## task 调用示例

```
task(
  subagent_type="explore",
  description="analyze target module",
  prompt="读取 {filePath}，按摘要模板返回：提取模块/类信息、关键函数签名与行号、调用关系、依赖。"
)
```
