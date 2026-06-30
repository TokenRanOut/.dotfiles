---
name: trace-spring-api-chain
description: 追踪Spring后端项目中任意入口方法的完整调用链路，自动识别入口类型并逐层追踪到数据访问和外部调用。适用：分析调用链、梳理业务链路、查调用关系。不适用：非Spring项目、单类分析、不追踪链路的代码审查/代码生成。Use when: tracing call chains, analyzing endpoint flows. Do NOT use for: non-Spring projects, isolated class analysis, non-tracing tasks.
---

# trace-spring-api-chain

！！！开始前必须先加载 code-explore skill。本 skill 遵循 code-explore 的文件读取规则、代码引用格式和分析原则。

## 适用场景
- 用户指定一个入口方法（HTTP/RPC/MQ/定时任务等），要求分析完整的后端调用链路
- 用户想了解某个业务操作从入口到落库的完整执行流程

## 核心原则

1. **逐层跳转** — 从入口方法注入的字段找到下一层实现类，逐层追踪
2. **输出适配** — 参考输出模板，按链路实际内容增减，不强行套固定模板

## 分析流程

### Step 0: 加载 code-explore skill
通过 skill 工具加载 code-explore skill，获取 subagent 摘要模板、分工规则、禁止行为、代码引用格式。

### Spring 特有分析维度

在 code-explore 通用摘要模板基础上，spawn subagent 时追加以下 Spring 特有提取项，主 agent 按对应输出维度整理：

| 模式 | Subagent 提取格式（追加到 prompt） | 主 agent 输出维度 |
|------|-----------------------------------|-------------------|
| 加锁 | RedisLockManager/@Lock 行号 | 加锁（分布式锁、本地锁） |
| 事务 | @Transactional 行号 | 数据库写操作（事务边界） |
| 缓存 | @Cacheable/@CacheEvict/redisTemplate 行号 | 缓存操作 |
| MQ | topic/queue @ 行号 | 消息发送 (MQ) |
| 事件 | ApplicationEventPublisher.publishEvent() @ 行号 | 事件发布 |
| Feign | feignClient.method() @ 行号 | Feign 远程调用 (@FeignClient) |
| 异步 | @Async 行号 (不继续追踪) | 异步调用 (标注中断点，不继续追踪) |
| 重试 | @Retryable 行号 | 重试 |
| 补偿 | — | 兜底/补偿逻辑 |

### Step 1: 探测项目架构
- 看 pom.xml / build.gradle 了解项目模块划分（配置文件可直接读，代码文件走 subagent）
- 用 `glob` 看顶层包结构，识别分层命名习惯（如 biz/process、service、repository、dao、manager 等）
- 确定本项目的典型调用路径：入口方法 → ? → ? → ? → DB / 外部调用

### Step 2: 定位入口

根据用户描述推断入口类型，若无法确定则向用户确认：

| 入口类型    | grep 搜索模式                                                                                             | Subagent 需提取的元数据                  |
|-------------|-----------------------------------------------------------------------------------------------------------|------------------------------------------|
| HTTP        | @PostMapping, @GetMapping, @RequestMapping, @RestController                                               | 方法、路径、请求/响应体                  |
| Dubbo       | @DubboService, @DubboReference, dubbo:service                                                             | 接口名、方法签名、版本号                 |
| Feign       | @FeignClient                                                                                              | 接口名、URL/服务名、fallback             |
| MQ Consumer | @RabbitListener, @KafkaListener, @RocketMQMessageListener, @PulsarListener, @JmsListener, @StreamListener | Queue/Topic、交换机、路由键、并发数      |
| 定时任务    | @Scheduled, @XxlJob, @ElasticJob, @PowerJob                                                               | cron、任务名                         |
| gRPC        | @GrpcService, extends.*ImplBase                                                                           | proto service 名、方法                   |
| 通用        | 包名 + 类名搜索（如 xxxFacade, xxxController, xxxService）                                                | 方法签名、注入字段                      |

- 主 agent 根据入口类型选择对应的 grep 模式，定位入口文件
- **！！必须 spawn subagent（见 code-explore 模板）分析入口文件**，提取元数据和下层调用列表（类/接口名与行号）

### Step 3: 逐层追踪
- **！！对每层发现的每个下层实现类，必须立即并行 spawn subagent 读取分析（见 code-explore 模板 + Spring 特有分析维度）**
- 主 agent 根据上一层 subagent 摘要中的「调用关系」信息，用 `grep` 定位下一层实现类
- 同层级的多个文件同时 spawn subagent，按摘要模板返回
- 从 subagent 摘要中按「Spring 特有分析维度」的输出维度列提取关键步骤，按代码执行顺序整理
- 继续追踪到数据访问层或外部 RPC 调用层，直到链路终点（Mapper/Repository/外部 RPC 接口）
- 每层追踪过程中，主 agent 汇总 subagent 返回的摘要，拼接链路

## 输出要求

参考以下模板，按链路实际内容增减：

1. **业务背景**
   - 2-4 句话，说清这个接口在业务中的定位、触发场景、上下游参与者
   - 如果接口在不同端都有入口（如 WX/APP），一并说明

2. **入口**
   - 表格列出每条入口的：入口类型、标识(路径/队列/topic/cron)、入口类名、`类名.方法名() @ 文件:行号`
   - 入口专属元数据（HTTP 的请求/响应体、MQ 的队列/topic、定时任务的 cron 等）
   - 若有相关接口（如同模块的预校验、取消等），列出

3. **核心链路（逐方法验证）**
   - 使用缩进树形文本图，层级对应实际调用链深度
   - 每行标注 `类名.方法名() @ 文件名:行号`，同文件跳转用 `行 → 行`
   - 包含关键参数和返回值说明
   - 外部 RPC 调用标注为 `→ 接口名.方法()`，标注实际 RPC 框架（Dubbo/Feign/gRPC）
   - 异步操作标注为 `→ MQ topic/queue`，事件发布标注为 `⇢ Event xxxEvent`

4. **校验/检查清单**（若链路中有集中校验逻辑）
   - 表格列出校验方法名称和校验内容
   - 区分阻断级和非阻断级

5. **数据操作汇总**（若有数据库写入）
   - 表格列出：序号、操作类型、表名、说明
   - 注明事务边界（标注事务方法名和行号）

6. **外部调用汇总**（若有 RPC / HTTP / MQ 调用）
   - 表格列出：调用目标、调用方式、`类名.方法名() @ 文件:行号`

7. **关键字段传递**（若链路上有核心业务字段需要跨层传递）
   - 表格列出：阶段、`类名.方法名()`、行号、行为

8. **代码位置速查表**
   - 汇总全文中所有标注过的代码引用
   - 表格：内容、类名.方法名()、文件、行号
