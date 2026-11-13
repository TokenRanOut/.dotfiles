---
name: quick-render-uml
description: Render PlantUML files, code, or user descriptions as SVG/PNG and preview the result. Excludes conceptual design discussions and diagrams in formats other than PlantUML.
tags: uml,plantuml,svg,png,render,preview
---

# quick-render-uml

Render PlantUML locally as SVG or PNG and preview it with macOS `open`.

## When to use

- Render and preview PlantUML from a `.puml` file, stdin, the clipboard, or a natural-language description.
- Turn pasted PlantUML code directly into an image.
- Produce an image from a described business flow or design rather than returning only code.

## Entry point

Keep the working directory in the target project. Set `QUICK_RENDER_UML_SKILL_DIR` to the absolute directory of the loaded skill, obtained from skill metadata rather than a hardcoded user path. Invoke the script by absolute path and keep rendering mechanics out of the user-facing explanation. Resolve relative input paths from the project's working directory.

When the user wants a UML image, use this skill to render it directly. If only a natural-language description is available, first produce minimal working PlantUML, then pipe it into `"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" stdin --name diagram` to render and preview it.

Default to SVG when the user does not specify a format. Switch to PNG only when explicitly requested.

```bash
# QUICK_RENDER_UML_SKILL_DIR is set; the working directory is the target project.
"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" doctor
"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" file doc/uml/recruit-order-sequence.puml
"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" file doc/uml/recruit-order-sequence.puml --png
"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" stdin --name diagram
"$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" clipboard --name diagram
```

## Script contract

- Require zsh and either Java with the bundled `lib/plantuml-*.jar` or a system `plantuml` command. Preview requires macOS `open`; clipboard input requires `pbpaste`.
- Prefer the bundled jar; automatically fall back to system `plantuml` when the jar engine is unavailable.
- Support only SVG and PNG, defaulting to SVG.
- Preview automatically with `open`; append `--no-open` when the user explicitly requests no preview.
- Write intermediate and output files only to temporary directories, never back into the project.
- Use `TMPDIR` as the temporary root, falling back to `/tmp`. The root must already exist. Use the runtime-provided path rather than a hardcoded machine-specific location. For example, when that path is assigned to `RUNTIME_TEMP_ROOT`:

  ```bash
  TMPDIR="$RUNTIME_TEMP_ROOT" "$QUICK_RENDER_UML_SKILL_DIR/bin/render-uml.sh" stdin --name diagram --no-open
  ```

- For stdin and clipboard input, `--name` is a single base file name (default: `diagram`), not a path. Reject empty names, `.` and `..`, and names containing `/` or `\` before creating temporary files or writing input. Spaces and non-English names are supported.
- Use `file ...` for existing `.puml` files in most cases.

## Output

- Tell the user the final temporary output path.
- Preserve PlantUML's original diagnostics if rendering fails. Failures return a nonzero exit status.

## Validation

Run local tests with Python 3.9+, zsh, Java, and the bundled jar. They verify executable permissions, syntax, SVG/PNG rendering under a caller-specified `TMPDIR` without preview, and rejection of path traversal in `--name`. No dependency installation or network access is required.

```bash
python3 -B "$QUICK_RENDER_UML_SKILL_DIR/tests/test_render_uml.py" -v
```
