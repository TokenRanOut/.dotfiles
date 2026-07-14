# Spring 入口模式速查

> 当 SKILL.md 中的入口速查表不足以精确定位时，加载本文件获取完整的 grep 模式和元数据清单。

## 入口类型详情

### HTTP

**grep 模式**: `@PostMapping|@GetMapping|@RequestMapping|@RestController|@Controller`

**匹配文件**: Controller 类（通常以 Controller 结尾，在 controller/ 包下）

**追加 grep**（定位具体方法）:
```
@PostMapping\s*\(|@GetMapping\s*\(|@RequestMapping\s*\(
```

**Subagent 需提取**:
- 类注解 (@RestController, @RequestMapping 基础路径)
- 方法注解对应的方法名、HTTP 路径、HTTP 方法
- 入参注解 (@RequestBody, @RequestParam, @PathVariable, @RequestHeader) 及类型
- 返回值类型（泛型展开）
- 自定义注解 (@ApiOperation, @PreAuthorize 等权限/文档标记)

### Dubbo

**grep 模式**: `@DubboService|@DubboReference|dubbo:service`

**匹配文件**: Dubbo 服务实现类 / 引用接口

**追加 grep**:
```
@DubboService|implements\s+\w+Facade
```

**Subagent 需提取**:
- 服务接口全限定名、版本号 (version)、组 (group)
- 方法签名（参数类型 + 返回值类型）
- interfaceClass 指定的接口
- timeout/retries/cluster 等配置
- 如有 @DubboReference，列出被引用的接口名

### Feign

**grep 模式**: `@FeignClient`

**匹配文件**: Feign 接口定义（通常在 feign/ 或 remote/ 包下）

**追加 grep**:
```
@FeignClient\s*\(
```

**Subagent 需提取**:
- name/value（服务名）、url、path
- fallback/fallbackFactory 实现类名
- configuration 类名
- 接口中每个方法的 @RequestMapping/@GetMapping/@PostMapping 路径和签名
- 熔断降级配置 (Hystrix/Sentinel)

**！！注意**: Feign 接口无本地实现，不搜索实现类。标注为终端节点。

### MQ Consumer

**grep 模式**: `@RabbitListener|@KafkaListener|@RocketMQMessageListener|@PulsarListener|@JmsListener|@StreamListener`

**匹配文件**: MQ 消费者类（通常在 consumer/ 或 mq/ 包下）

**追加 grep** (按框架):
- RabbitMQ: `queues\s*=|bindings\s*=`
- Kafka: `topics\s*=|topicPattern\s*=`
- RocketMQ: `topic\s*=|consumerGroup\s*=|tag\s*=`
- Pulsar: `subscriptionName\s*=|topic\s*=`

**Subagent 需提取**:
- Queue/Topic 名称、交换机 (exchange)、路由键 (routingKey)
- 消费者组 (consumerGroup)、并发数 (concurrency/concurrencyLimit)
- 消息体类型（方法参数类型）
- 确认机制 (ackMode)、批量消费配置
- 死信队列 / 重试队列配置

### 定时任务

**grep 模式**: `@Scheduled|@XxlJob|@ElasticJob|@PowerJob|@QuartzJob`

**匹配文件**: 任务类（通常在 job/ 或 schedule/ 包下）

**追加 grep** (按框架):
- Spring: `@Scheduled\s*\(.*cron|fixedRate|fixedDelay`
- XXL-JOB: `@XxlJob\s*\(`
- ElasticJob: `@ElasticSimpleJob|@ElasticDataflowJob`
- PowerJob: `@PowerJobHandler`

**Subagent 需提取**:
- cron 表达式 / fixedRate / fixedDelay
- 任务名 (如 XXL-JOB 的 jobHandler name)
- 分片策略
- 是否支持并发执行
- 任务参数

### gRPC

**grep 模式**: `@GrpcService|extends\s+\w+ImplBase`

**匹配文件**: gRPC 服务实现类

**追加 grep**:
```
@GrpcService
```

**Subagent 需提取**:
- proto service 名、包名
- 方法名、请求/响应消息类型
- Stream 类型 (UNARY / SERVER_STREAMING / CLIENT_STREAMING / BIDI_STREAMING)
- 拦截器

### 通用（无明确注解）

当用户只给类名或包名时：

**grep 模式**: 按用户提供的类名/方法名在模块中搜索

**常见命名惯例**:
- `*Facade` — 对外门面层（Dubbo/HTTP 入口）
- `*Controller` — HTTP 控制器
- `*ServiceImpl` / `*BizServiceImpl` — 业务实现
- `*Manager` — 领域管理器
- `*Repository` / `*Dao` / `*Mapper` — 数据访问层
- `*Consumer` / `*Listener` — MQ 消费者

**当无法确定时**: 向用户确认入口类型，列出候选文件和类型。
