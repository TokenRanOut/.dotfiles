---
name: java-signature
description: 在 Maven 项目中查询外部依赖的类结构、方法签名或类名归属时使用。不用于非 Maven 项目、读取 jar 资源或追踪项目内部实现。
---

# java-signature — IDE 式代码提示

给 agent 提供类似 IDE 自动补全的能力：只给**类全名 + Maven 项目根目录**，即可拿到该类的方法签名与类结构，无需关心类在哪个 jar、更无需解压 jar。

## 适用场景

- 接入外部依赖时，确认某个类的全名、方法签名、返回值
- 不确定类名时按关键词搜类
- 确认某依赖的坐标或 jar 归属

## 执行入口

所有命令的 `--project <dir>` 指向 Maven 项目根目录，缺省为当前工作目录。

```bash
# 查看类结构/方法签名（核心命令）
./bin/java-signature.sh class com.example.OrderService --project /path/to/project

# 按正则搜索类名，结果带 jar 名标注（不确定类名时用）
./bin/java-signature.sh find Order --project /path/to/project

# 列出全部依赖 jar 路径
./bin/java-signature.sh list --project /path/to/project
```

示例：

```bash
./bin/java-signature.sh class org.apache.commons.lang3.StringUtils --project /Users/me/myapp
# 输出：public static boolean isBlank(CharSequence cs); 等 javap -p -s 结果

./bin/java-signature.sh find RabbitListener --project /Users/me/myapp
# 输出：spring-rabbit-2.4.8.jar: org.springframework.amqp.rabbit.annotation.RabbitListener
```

## 实现原理

1. `mvn dependency:build-classpath` 解析项目全部依赖 jar 的 classpath
2. `class`：内部按类全名定位目标 jar，再用 `javap -p -s -classpath <完整依赖classpath> <类名>` 直接反编译，**零解压**
3. `find`：对每个依赖 jar 执行 `jar tf` 生成清单后 grep，标注所属 jar
4. 全流程按内容 hash 缓存

## 缓存机制

缓存根目录 `~/.cache/java-signature/`（可用 `XDG_CACHE_HOME` 覆盖）：

| 缓存 | 路径 | 失效条件 |
|------|------|----------|
| 依赖 classpath | `projects/<pom-hash>/classpath.txt` | pom.xml 变更 |
| jar 清单 | `jars/<jar-md5>/listing.txt` | jar 内容变化 |
| javap 输出 | `jars/<jar-md5>/signatures/<类名>.javap` | 目标 jar 内容变化 |

- 首次调用需跑 maven 解析依赖，较慢（10s+）；之后全部走缓存，秒回
- 若 pom 依赖变更而缓存未自动刷新，删除 `~/.cache/java-signature/projects/<pom-hash>/` 后重跑
- 缓存 key 取项目根 pom.xml 的 md5，多模块项目请在目标模块目录执行 `--project`；父 pom 变更可能不触发子模块缓存失效

## 依赖

- Maven（mvn），仅首次解析 classpath 时需要
- JDK：jar、javap（自动识别 `JAVA_HOME`，回退到 PATH）

## 注意事项

- 类全名可带 `.class` 后缀，脚本自动去除
- 同名类出现在多个依赖 jar 时，`class` 取 classpath 中第一个命中
- `find` 大小写不敏感，支持正则
- 输出全部走 stdout，诊断信息走 stderr，方便管道处理

## 禁止行为

- ❌ 不要手动 `jar xf` 解压依赖 jar，脚本已按需自动读取
- ❌ 不要硬编码某个 jar 的路径去 javap，`--project` 会自动解析
- ❌ 不要对非 Maven 项目使用本脚本
