---
name: java-signature
description: Inspect external dependency class structures, method signatures, or class ownership in Maven projects. Excludes non-Maven projects, reading jar resources, and tracing project-internal implementations.
---

# java-signature

Retrieve public class structures and method signatures from a fully qualified class name and a Maven project directory, without locating or extracting jars manually.

## When to use

- Confirm external dependency class names, method signatures, and return types.
- Search class names by keyword when the full name is unknown.
- Identify the dependency jar that owns a class and use its path to identify dependency coordinates.

## Entry point

Keep the working directory in the target project. Set `JAVA_SIGNATURE_SKILL_DIR` to the absolute directory of the loaded skill, obtained from skill metadata rather than a hardcoded user path. Invoke the script by absolute path and explicitly pass `--project <absolute-project-path>`. The script also supports omitting `--project`, defaulting to the working directory.

```bash
# JAVA_SIGNATURE_SKILL_DIR is set; the working directory is the Maven project.
PROJECT_DIR="$PWD"

# Inspect public class structures and signatures.
"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" class com.example.OrderService --project "$PROJECT_DIR"

# Search class names by regex, with owning jar names in the results.
"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" find Order --project "$PROJECT_DIR"

# List dependency jar paths.
"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" list --project "$PROJECT_DIR"

# Rebuild the classpath after changes outside the selected pom.xml.
"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" list --project "$PROJECT_DIR" --refresh
```

Examples:

```bash
"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" class org.apache.commons.lang3.StringUtils --project "$PROJECT_DIR"
# Includes: public static boolean isBlank(java.lang.CharSequence);

"$JAVA_SIGNATURE_SKILL_DIR/bin/java-signature.sh" find RabbitListener --project "$PROJECT_DIR"
# Example: spring-rabbit-2.4.8.jar: org.springframework.amqp.rabbit.annotation.RabbitListener
```

## Implementation

1. Resolve dependency jar paths with `mvn dependency:build-classpath`.
2. For `class`, locate the class in the dependency jars, then run `javap -public -s -classpath <full-dependency-classpath> <class-name>` without extraction. Do not add `target/classes`; fail when the class is absent from dependency jars.
3. For `find`, cache each jar's `jar tf` listing and search it, labeling matches with the owning jar.
4. Cache results by project identity and content hashes.

## Cache

The cache root is `${XDG_CACHE_HOME:-$HOME/.cache}/java-signature/`.

| Cache | Relative path | Invalidation |
|---|---|---|
| Dependency classpath | `projects/<canonical-path-hash>/<pom-hash>/classpath.txt` | Selected `pom.xml` content or newer modification time; explicit `--refresh` |
| Jar listing | `jars/<jar-md5>/listing.txt` | Jar content changes |
| Public signatures | `jars/<jar-md5>/signatures-public-v1/<class-name>.javap` | Target jar content changes; separate namespace excludes old private-member caches |

- The project identity is the MD5 of its physical absolute directory (`pwd -P`). Identical POMs in different directories have separate classpath caches; symlink aliases share the same identity.
- Initial classpath resolution invokes Maven and can take 10 seconds or more. Later calls reuse cached results.
- Point `--project` at the target module in a multi-module project.
- Only the selected directory's `pom.xml` is tracked automatically. Changes to parent POMs, other modules, Maven settings, active profiles, environment variables, local repository contents, or remote artifacts do not automatically invalidate the classpath cache.
- Add `--refresh` to `class`, `find`, or `list` to discard and rebuild that project's current classpath cache. Jar listings and signatures still use content hashes. Refresh invokes normal Maven resolution, not Maven's forced remote-update mode.

## Dependencies

- Bash and standard shell utilities, including `md5` or `md5sum`.
- Maven (`mvn`), needed when resolving or refreshing the classpath; use `MAVEN_HOME` or `PATH`.
- JDK tools `jar` and `javap`; use `JAVA_HOME` with a `PATH` fallback.

## Validation

Run the local tests with Python 3 and `javac`, `jar`, and `javap` on `PATH`. A Maven substitute verifies public signatures, cache reuse and invalidation, project-directory isolation, explicit refresh, symlink normalization, dependency precedence over project classes, and rejection of project-only classes without Maven network access.

```bash
python3 -B "$JAVA_SIGNATURE_SKILL_DIR/tests/test_java_signature.py" -v
```

## Usage rules

- A class name may include a `.class` suffix; the script removes it.
- If multiple dependency jars contain the same class, `class` uses the first match in classpath order.
- Return only public members and type descriptors. Project classes are not queried and cannot shadow dependency signatures.
- `find` supports case-insensitive regular expressions.
- Results go to stdout, diagnostics to stderr, and failures return a nonzero exit status.
- Do not extract dependency jars with `jar xf` or hardcode jar paths for `javap`; use the script's project-based resolution.
- Do not use this script for non-Maven projects.
