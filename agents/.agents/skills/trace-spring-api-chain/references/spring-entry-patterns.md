# Spring Entry-Point Patterns

Read this reference when the entry point is unclear or detailed search patterns are needed. Extract the metadata below directly or include it in delegated tasks; do not create one subagent per class.

## Entry types

### HTTP

**grep pattern**: `@PostMapping|@GetMapping|@RequestMapping|@RestController|@Controller`

**Files**: Controller classes, commonly ending in Controller under a controller/ package.

**Additional grep** to locate specific methods:
```
@PostMapping\s*\(|@GetMapping\s*\(|@RequestMapping\s*\(
```

**Extract**:
- Class annotations (`@RestController`, `@RequestMapping` base path).
- Annotated method names, HTTP paths, and HTTP methods.
- Parameter annotations (`@RequestBody`, `@RequestParam`, `@PathVariable`, `@RequestHeader`) and types.
- Return types, expanding generics.
- Additional annotations such as `@ApiOperation` and `@PreAuthorize` for documentation or permissions.

### Dubbo

**grep pattern**: `@DubboService|@DubboReference|dubbo:service`

**Files**: Dubbo service implementations and referenced interfaces.

**Additional grep**:
```
@DubboService|implements\s+\w+Facade
```

**Extract**:
- Fully qualified service interface names, version, and group.
- Method signatures, including parameter and return types.
- The interface specified by interfaceClass.
- Configuration such as timeout, retries, and cluster.
- Referenced interface names when `@DubboReference` is present.

### Feign

**grep pattern**: `@FeignClient`

**Files**: Feign interface declarations, commonly under feign/ or remote/ packages.

**Additional grep**:
```
@FeignClient\s*\(
```

**Extract**:
- name/value (service name), url, and path.
- fallback/fallbackFactory implementation class names.
- configuration class names.
- `@RequestMapping`/`@GetMapping`/`@PostMapping` paths and signatures for each interface method.
- Circuit-breaker/fallback configuration (Hystrix/Sentinel).

Feign defines a remote-call contract; do not require a local generated implementation. Verify fallbacks when applicable. Continue into remote services only according to the user's goal and explicitly included repositories, marking remote boundaries separately.

### MQ Consumer

**grep pattern**: `@RabbitListener|@KafkaListener|@RocketMQMessageListener|@PulsarListener|@JmsListener|@StreamListener`

**Files**: MQ consumer classes, commonly under consumer/ or mq/ packages.

**Additional grep** by framework:
- RabbitMQ: `queues\s*=|bindings\s*=`
- Kafka: `topics\s*=|topicPattern\s*=`
- RocketMQ: `topic\s*=|consumerGroup\s*=|tag\s*=`
- Pulsar: `subscriptionName\s*=|topic\s*=`

**Extract**:
- Queue/topic names, exchange, and routingKey.
- consumerGroup and concurrency/concurrencyLimit.
- Payload types from method parameters.
- Acknowledgment mode (ackMode) and batch-consumption configuration.
- Dead-letter and retry queue configuration.

### Scheduled jobs

**grep pattern**: `@Scheduled|@XxlJob|@ElasticJob|@PowerJob|@QuartzJob`

**Files**: Job classes, commonly under job/ or schedule/ packages.

**Additional grep** by framework:
- Spring: `@Scheduled\s*\(.*cron|fixedRate|fixedDelay`
- XXL-JOB: `@XxlJob\s*\(`
- ElasticJob: `@ElasticSimpleJob|@ElasticDataflowJob`
- PowerJob: `@PowerJobHandler`

**Extract**:
- cron expressions, fixedRate, or fixedDelay.
- Job names, such as XXL-JOB jobHandler names.
- Sharding strategies.
- Whether concurrent execution is supported.
- Job parameters.

### gRPC

**grep pattern**: `@GrpcService|extends\s+\w+ImplBase`

**Files**: gRPC service implementations.

**Additional grep**:
```
@GrpcService
```

**Extract**:
- Proto service and package names.
- Method names and request/response message types.
- Stream types (UNARY / SERVER_STREAMING / CLIENT_STREAMING / BIDI_STREAMING).
- Interceptors.

### General (no specific annotation)

When the user supplies only a class or package name:

**grep pattern**: Search the module using the supplied class or method name.

**Common naming conventions**:
- `*Facade` — External facade (Dubbo/HTTP entry).
- `*Controller` — HTTP controller.
- `*ServiceImpl` / `*BizServiceImpl` — Business implementation.
- `*Manager` — Domain manager.
- `*Repository` / `*Dao` / `*Mapper` — Data-access layer.
- `*Consumer` / `*Listener` — MQ consumer.

**When unresolved**: List candidate files and types and ask the user to confirm the entry type.
