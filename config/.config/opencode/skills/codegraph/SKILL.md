---
name: codegraph
description: >
  分析本地代码的调用者、被调用者、模块关系、业务实现链路或修改影响范围时使用。
  不用于普通文件查找、已知文件的局部阅读或索引管理。
---

# codegraph

## 适用场景

- 需要理解模块关系或跨文件业务实现链路
- 需要查询符号的调用者、被调用者或修改影响范围
- 跨项目任务中，需要分别获取每个项目的结构化代码证据

`code-explore` 负责通用探索范围与证据规范，本技能负责查询工具选择和使用，不替代领域分析与源码核验。

## 核心原则

1. **当前 Agent 直接调用** — 通过 Shell 执行 `codegraph` CLI；不得仅为运行 CodeGraph 而委托 OpenCode `explore` 子代理。
2. **每次只查一个项目** — 先确定最近的 `.codegraph/` 所在项目根目录；每条命令都显式传入绝对 `--path`。
3. **最小充分输出** — 按问题选择查询范围，仅获取支撑结论所需的源码；调用关系查询可从 20 条、影响范围可从深度 2 开始，证据不足时继续定向查询，不将初始范围视为完整结果。
4. **证据优先** — `explore` 或 `node` 返回的源码及行号可直接作为证据；仅有名称或统计信息不足以证明实现行为。
5. **只读查询** — 未经用户明确要求，不初始化、重建、同步、安装或卸载 CodeGraph。

## 工作流程

- [ ] 确定目标文件或符号所属项目根目录；在任务允许的项目范围内查找 `.codegraph/`，嵌套仓库选择最近的 `.codegraph/` 父目录，不扫描无关目录。
- [ ] 若没有 `.codegraph/`，直接回退源码搜索；若存在，检查 CLI 是否可用，再通过 `codegraph status <项目根目录> --json` 确认索引状态。
- [ ] 索引可用时，优先按问题选择最小结构化查询；已知符号使用 `node`、调用关系或影响范围查询，模块关系与跨文件业务链路使用 `explore`。
- [ ] 若缺少索引、CLI 不可用或结果不足，只对该项目回退到 `glob`、`grep` 和定向读取。
- [ ] 结论中给出项目根目录、文件路径、符号和行号；跨项目结论分别取证后再关联。

## 查询命令

```bash
# 业务流程或模块关系
codegraph explore --path /absolute/project "订单创建流程"

# 已知符号或文件的源码及关联关系
codegraph node --path /absolute/project OrderService
codegraph node --path /absolute/project --file src/main/java/example/OrderService.java

# 调用关系与修改影响
codegraph callers --path /absolute/project --limit 20 createOrder
codegraph callees --path /absolute/project --limit 20 createOrder
codegraph impact --path /absolute/project --depth 2 OrderService
```

## 降级与边界

- 没有 `.codegraph/` 或 `status` 显示未初始化时，不运行 `codegraph init`；改用普通源码工具。
- 索引结果包含异常目录、重复符号或关系时，报告问题；未经用户要求不修改 ignore 配置。
- 同名符号、不同项目的查询结果，不构成跨项目调用证据；必须再找到接口契约、依赖声明、调用点或配置关联。
- 索引可能滞后于刚写入的文件；出现过期提示时，只定向读取受影响文件。

## 禁止行为

- ❌ 不传 `--path`，或把源文件路径、`.codegraph/` 目录误作项目根目录
- ❌ 一条命令混合多个项目，或把分别查询的结果误写为自动发现的跨项目调用边
- ❌ 为运行 CodeGraph 而创建或委托 `explore` 子代理
- ❌ 自动执行 `codegraph init`、`index`、`sync`、`install`、`uninstall` 或 `serve --mcp`
- ❌ 对 CodeGraph 已返回的带行号源码重复执行同等范围的读取
