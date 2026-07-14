---
name: trace-spring-api-chain
description: >
  Use this skill when you need to trace the full call chain of any entry-point
  method in a Spring backend project — from HTTP/RPC/MQ/Job entry, through
  service layers, down to database access and external calls. Use it when the
  user asks to "analyze call chains", "trace endpoint flows", "understand the
  business flow", or wants to see what happens end-to-end when a particular API
  is invoked. Do NOT use for: non-Spring projects, isolated single-class
  analysis, code review that doesn't involve tracing a complete chain, or code
  generation tasks. 适用：追踪 Spring 后端任意入口方法的完整调用链路、梳理业务
  链路、分析接口执行流程。不适用：非 Spring 项目、单独分析某个类、不追踪链路的
  代码审查或代码生成。
tags: spring,tracing,call-chain,backend
---

# trace-spring-api-chain

> **前置依赖**: ！！开始前必须先用 `skill` 工具加载 **code-explore** skill。本 skill 遵循 code-explore 的文件读取规则、代码引用格式和分析原则。

## 适用场景

- 用户指定一个入口方法（HTTP/RPC/MQ/定时任务等），要求分析完整的后端调用链路
- 用户想了解某个业务操作从入口到落库的完整执行流程

## 核心原则

1. **逐层跳转** — 从入口方法注入的字段找到下一层实现类，逐层追踪，不跳跃
2. **输出适配** — 参考输出模板，按链路实际内容增减，不强行套固定模板
3. **并行分析** — 同层级的多个文件同时 spawn subagent，不等串行
4. **中断标注** — 遇到异步/线程切换/MQ 发布时标注中断点，不跨边界追踪

## 工作流程

进度：
- [ ] Step 0: 加载 code-explore skill
- [ ] Step 1: 探测项目架构 — pom.xml/gradle 模块划分 + 顶层包结构
- [ ] Step 2: 定位入口 — 根据类型 grep 定位文件，spawn subagent 分析
- [ ] Step 3: 逐层追踪 — 每层并行 spawn subagent，汇总拼接链路
- [ ] Step 4: 输出自检 — 对照自检清单核验完整性和准确性

### Step 0: 加载 code-explore skill

通过 `skill` 工具加载 code-explore skill，获取 subagent 摘要模板、分工规则、禁止行为、代码引用格式。

### Step 1: 探测项目架构

- 看 pom.xml / build.gradle 了解项目模块划分
- 用 `glob` 看顶层包结构，识别分层命名习惯（如 biz/process、service、repository、dao、manager 等）
- 确定本项目的典型调用路径：入口方法 → ? → ? → ? → DB / 外部调用

### Step 2: 定位入口

根据用户描述推断入口类型，若无法确定则向用户确认。入口类型及 grep 模式详见 **`references/spring-entry-patterns.md`**（当入口类型不确定或需要详尽模式时读取）。

简要速查：

| 入口类型 | 典型 grep 关键词 | Subagent 需提取的元数据 |
|----------|-------------------|------------------------|
| HTTP | @PostMapping, @GetMapping, @RestController | 方法、路径、请求/响应体 |
| Dubbo | @DubboService, dubbo:service | 接口名、方法签名、版本号 |
| Feign | @FeignClient | 接口名、URL/服务名、fallback |
| MQ Consumer | @RabbitListener, @KafkaListener, @RocketMQMessageListener | Queue/Topic、交换机、路由键 |
| 定时任务 | @Scheduled, @XxlJob, @ElasticJob | cron、任务名 |
| gRPC | @GrpcService, extends.*ImplBase | proto service 名、方法 |

- 主 agent 根据入口类型选择对应的 grep 模式，定位入口文件
- **！！必须 spawn subagent 分析入口文件**，提取元数据和下层调用列表（类/接口名与行号）

### Step 3: 逐层追踪

- **！！对每层发现的每个下层实现类，必须立即并行 spawn subagent 读取分析**
- 主 agent 根据上一层 subagent 摘要中的「调用关系」信息，用 `grep` 定位下一层实现类
- 同层级的多个文件同时 spawn subagent，按摘要模板 + Spring 特有分析维度返回
- 从 subagent 摘要中提取关键步骤，按代码执行顺序整理
- 继续追踪到数据访问层或外部 RPC 调用层，直到链路终点（Mapper/Repository/外部 RPC 接口）
- 每层追踪过程中，主 agent 汇总 subagent 返回的摘要，拼接链路

#### Subagent prompt 追加项（Spring 特有分析维度）

在 code-explore 通用摘要模板基础上，spawn subagent 时追加以下提取指令：

| 模式 | 追加到 subagent prompt |
|------|----------------------|
| 加锁 | 标注 RedisLockManager/@Lock/@Synchronized 的锁类型、key、超时 |
| 事务 | 标注 @Transactional 的传播级别、只读标志，定位 begin/commit/rollback |
| 缓存 | 标注 @Cacheable/@CacheEvict/@CachePut/redisTemplate 的 cache name、key、TTL |
| MQ 发送 | 标注 RabbitTemplate/KafkaTemplate/RocketMQTemplate 的 topic/queue、消息体 |
| 事件发布 | 标注 ApplicationEventPublisher.publishEvent() 的事件类型 |
| Feign 调用 | 标注 @FeignClient 方法调用的 URL、fallback、熔断配置 |
| 异步 | 标注 @Async/@EventListener(asynchronous) — **不继续追踪**，标记中断点 |
| 重试 | 标注 @Retryable 的 maxAttempts、backoff、include/exclude |
| 补偿 | 标注 catch 块中的补偿逻辑、Saga 回滚、@Recover 方法 |

#### 主 agent 输出维度汇总

主 agent 按以下维度整理汇总结果：

| 输出维度 | 说明 |
|---------|------|
| 加锁 | 分布式锁 / 本地锁位置与参数 |
| 事务边界 | @Transactional 方法及传播行为 |
| 缓存操作 | Cache 读写位置与 key 策略 |
| 消息发送 (MQ) | Topic/Queue 及发送位置 |
| 事件发布 | 事件类型与发布位置 |
| Feign 远程调用 | 目标服务、URL、fallback |
| 异步调用 | 标注中断点，不深入追踪 |
| 重试 | 重试策略与配置 |
| 兜底/补偿 | 失败回退逻辑 |

### Step 4: 输出自检

对照以下清单逐项核验：

- [ ] 每层调用都有对应的 subagent 分析结果
- [ ] 所有代码引用格式为 `ClassName.methodName() @ FileName:行号` 或 `行 → 行`
- [ ] 树形缩进层级与实际调用深度一致
- [ ] MQ 发送 / 异步 / 事件发布 标注了中断点
- [ ] 外部 RPC 调用标注了框架类型（Dubbo/Feign/gRPC/HTTP）
- [ ] 入口表、速查表、数据操作表等附属表格内容与正文引用一致

## 输出要求

参考以下模板，按链路实际内容增减：

### 1. 业务背景

2-4 句话，说清这个接口在业务中的定位、触发场景、上下游参与者。如果接口在不同端都有入口（如 WX/APP），一并说明。

### 2. 入口

- 表格列出每条入口的：入口类型、标识(路径/队列/topic/cron)、入口类名、`类名.方法名() @ 文件:行号`
- 入口专属元数据（HTTP 的请求/响应体、MQ 的队列/topic、定时任务的 cron 等）
- 若有相关接口（如同模块的预校验、取消等），列出

### 3. 核心链路（逐方法验证）

- 使用缩进树形文本图，层级对应实际调用链深度
- 每行标注 `类名.方法名() @ 文件名:行号`，同文件跳转用 `行 → 行`
- 包含关键参数和返回值说明
- 外部 RPC 调用标注为 `→ 接口名.方法()`，标注实际 RPC 框架（Dubbo/Feign/gRPC）
- MQ 发送标注为 `→ MQ topic/queue`
- 事件发布标注为 `⇢ Event xxxEvent`
- 异步调用标注为 `⟳ @Async`（中断点）

### 4. 校验/检查清单（若链路中有集中校验逻辑）

- 表格列出校验方法名称和校验内容
- 区分阻断级和非阻断级

### 5. 数据操作汇总（若有数据库写入）

- 表格列出：序号、操作类型、表名、说明
- 注明事务边界（标注事务方法名和行号）

### 6. 外部调用汇总（若有 RPC / HTTP / MQ 调用）

- 表格列出：调用目标、调用方式、`类名.方法名() @ 文件:行号`

### 7. 关键字段传递（若链路上有核心业务字段需要跨层传递）

- 表格列出：阶段、`类名.方法名()`、行号、行为

### 8. 代码位置速查表

- 汇总全文中所有标注过的代码引用
- 表格：内容、类名.方法名()、文件、行号

## Gotchas

以下是追踪 Spring 调用链时最容易踩的坑：

- **AOP 代理断链** — Spring AOP / CGLIB 代理的类，调用栈中可能只看到代理类而非实际实现。用注入字段的类型而非运行时期类型来定位下一层。
- **@Async 跨越线程** — `@Async` 注解的方法运行在新线程中，调用栈断裂。标注中断点后不继续追踪线程内的逻辑，除非用户明确要求。
- **@Transactional 自调用** — 同一类中方法 A 调用带 `@Transactional` 的方法 B，事务不生效。标注此情况但不作为事务边界。
- **Feign 接口无本地实现** — `@FeignClient` 接口的实现不在本地代码库。标注为终端节点，列出 URL 和方法签名，不搜索实现类。
- **MyBatis 拦截器** — SQL 可能被 MyBatis Plugin / Interceptor 增强（分表、加密、审计）。若项目中配置了拦截器，注明可能的副作用。
- **循环依赖陷阱** — A 注入 B，B 注入 A（即使是间接的）。追踪时记录已访问过的类，避免无限循环。
- **条件注入** — `@ConditionalOnProperty` / `@ConditionalOnBean` 等条件注入可能导致不同环境走不同实现。以当前激活的 profile 为准。

## ！！禁止行为

- ❌ 主 agent 直接用 `read` 读取代码文件（超过 30 行）—— 必须 spawn subagent
- ❌ 跳过中间层直接从入口跳到 Mapper/Repository
- ❌ 串行调用互无依赖的 subagent 任务
- ❌ 跨 @Async / MQ / 线程池边界继续追踪（标注中断点即可）
- ❌ 对 Feign 接口 / Dubbo 引用在本地搜索实现类
- ❌ 输出时省略代码引用格式中的文件:行号
