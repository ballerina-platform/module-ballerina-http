---
name: ballerina-java25-gradle-migration
description: Migrates a Ballerina stdlib module from Gradle 8.x/Java 21 to Gradle 9.5.1 and Java 25. Use this skill whenever the user asks to do a Java 25 migration, Gradle 9.5.1 upgrade, java-25-migration branch work, or any version migration for a Ballerina stdlib module. After all code changes pass the build, the skill pushes to the upstream java-25-migration branch and creates a PR to master/main. Use this skill proactively whenever a Ballerina module repo is mentioned alongside any migration, upgrade, or java25 context — even if the user doesn't say "skill".
---

## What this skill does

Migrates a Ballerina stdlib module from Gradle 8.x + Java 21 to Gradle 9.5.1 + Java 25 by making
targeted, verified changes to the build system, verifying with a **full local build including tests**,
then pushing to `upstream/java-25-migration` and opening a PR. The goal is a clean `./gradlew build`
(full build + tests) with no errors **before** committing to the upstream repository.

## Version Pins

Always use these exact versions — do not deviate:

| Component | Version |
|---|---|
| Gradle wrapper | `9.5.1` |
| `ballerinaGradlePluginVersion` | `4.0.0` |
| `ballerinaLangVersion` | `2201.14.0-20260527-050400-74f7e6bf` |
| SpotBugs plugin (any `*spotbugs*` key) | `6.5.1` |
| `net.researchgate.release` (any `*release*` key) | `3.1.0` |
| Develocity plugin (settings.gradle) | `3.19.2` |
| `jacocoVersion` | `0.8.13` |

---

## Step 1 — Branch setup

```bash
git checkout -b java-25-migration 2>/dev/null || git checkout java-25-migration
```

---

## Step 2 — gradle/wrapper/gradle-wrapper.properties

Replace the `distributionUrl` line:
```
distributionUrl=https\://services.gradle.org/distributions/gradle-9.5.1-bin.zip
```

---

## Step 3 — settings.gradle

### 3a. Replace enterprise plugin with Develocity
```groovy
// Before
plugins {
    id "com.gradle.enterprise" version "..."
}

// After
plugins {
    id "com.gradle.develocity" version "3.19.2"
}
```

### 3b. Replace gradleEnterprise block
```groovy
// Before
gradleEnterprise {
    buildScan {
        termsOfServiceUrl = 'https://gradle.com/terms-of-service'
        termsOfServiceAgree = 'yes'
    }
}

// After
develocity {
    buildScan {
        termsOfUseUrl = 'https://gradle.com/terms-of-service'
        termsOfUseAgree = 'yes'
    }
}
```
Note: the property names changed (`termsOfService*` → `termsOfUse*`).

### 3c. Add mavenLocal() to pluginManagement repositories
```groovy
pluginManagement {
    repositories {
        mavenLocal()       // add this first
        gradlePluginPortal()
        // ... rest unchanged
    }
}
```

---

## Step 4 — gradle.properties

Update these properties (grep for the key names — they vary across repos):

```bash
# Find the right keys
grep -i "spotbugs\|release\|ballerinaGradle\|ballerinaLang\|jacoco" gradle.properties
```

| What to find | New value |
|---|---|
| Key containing `spotbugs` and `version` (e.g. `spotbugsPluginVersion`, `githubSpotbugsVersion`) | `6.5.1` |
| Key for `net.researchgate.release` (e.g. `releasePluginVersion`, `researchgateReleaseVersion`) | `3.1.0` |
| `ballerinaGradlePluginVersion` | `4.0.0` |
| `ballerinaLangVersion` | `2201.14.0-20260527-050400-74f7e6bf` |
| Key containing `jacoco` and `version` (e.g. `jacocoVersion`) | `0.8.13` |

> **Important — `ballerinaLangVersion`**: Always replace with the exact timestamped version above,
> even if the repo already has a SNAPSHOT value like `2201.14.0-SNAPSHOT`. Generic SNAPSHOTs will
> resolve to whatever was last published and will not match local Maven artifacts from the build.

---

## Step 5 — root build.gradle

### 5a. Fix `task build` conflict
`net.researchgate.release` 3.1.0 registers its own `build` lifecycle task. If the root
`build.gradle` declares `task build { ... }`, rename it to avoid a conflict:

```groovy
// Before
task build {
    dependsOn('some-subproject:build')
}

// After
tasks.named('build') {
    dependsOn('some-subproject:build')
}
```

### 5b. Add Java 25 toolchain to subprojects
In the `subprojects { }` block, add inside a `plugins.withId('java')` guard:

```groovy
subprojects {
    // ...existing content...
    plugins.withId('java') {
        java {
            toolchain {
                languageVersion = JavaLanguageVersion.of(25)
            }
        }
    }
}
```

---

## Step 6 — Fix deprecated `buildDir` in all build.gradle files

Gradle 9 removed the `buildDir` property. Scan every `build.gradle`:

```bash
grep -rn "buildDir\|\.enabled = true" --include="*.gradle" .
```

Apply these replacements:

| Old | New |
|---|---|
| `buildDir` (bare, as a file reference) | `layout.buildDirectory.get().asFile` |
| `"$buildDir/some/path"` or `"${buildDir}/some/path"` | `layout.buildDirectory.dir("some/path").get().asFile` |
| `dest buildDir` | `dest layout.buildDirectory.get().asFile` |
| `reportsDir = file("$project.buildDir/reports/spotbugs")` | `reportsDir = layout.buildDirectory.dir("reports/spotbugs").get().asFile` |
| `file("${buildDir}/checkstyle.xml")` in `artifacts.add(...)` | `layout.buildDirectory.file("checkstyle.xml")` |
| `html.enabled = true` / `text.enabled = true` | `html.required = true` / `text.required = true` |
| jacoco `reportsDirectory = file("${buildDir}/reports/jacoco")` | `reportsDirectory = layout.buildDirectory.dir("reports/jacoco")` |
| jacoco `destinationFile = file("${buildDir}/jacoco/test.exec")` | `destinationFile = layout.buildDirectory.file("jacoco/test.exec").get().asFile` |

### Also check for hardcoded jacoco toolVersion in build.gradle files

Some modules hardcode the JaCoCo version directly in individual `build.gradle` files rather than
using the `jacocoVersion` property from `gradle.properties`. JaCoCo older than 0.8.12 cannot
instrument Java 25 class files (major version 69).

```bash
grep -rn "toolVersion.*0\.8\." --include="*.gradle" .
```

For any file that has `toolVersion = "0.8.10"` (or older) inside a `jacoco { }` block:
```groovy
// Before
jacoco {
    toolVersion = "0.8.10"
}

// After
jacoco {
    toolVersion = "0.8.13"
}
```

---

## Step 7 — Remove deprecated sourceCompatibility / targetCompatibility

When a Java toolchain is configured (Step 5b), Gradle 9 does not allow
`sourceCompatibility` / `targetCompatibility` to be set alongside it — this causes a conflict
or warning. Scan all `build.gradle` files:

```bash
grep -rn "sourceCompatibility\|targetCompatibility" --include="*.gradle" .
```

Remove any lines that set these to `JavaVersion.VERSION_21` (or `'21'`, `21`). If they reference
a different version that the project genuinely needs, keep them, but that is unlikely during this
migration since the toolchain now controls the version.

Example:
```groovy
// Remove this — toolchain handles it
sourceCompatibility = JavaVersion.VERSION_21
targetCompatibility = JavaVersion.VERSION_21
```

---

## Step 8 — ballerina/build.gradle: ExecOperations + script patching

`Project.exec()` was removed in Gradle 9. Also, the extracted `bal` binary needs patching for Java 25.

### 8a. Add imports at the top of the file
```groovy
import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.process.ExecOperations
import org.gradle.jvm.toolchain.JavaLanguageVersion
import org.gradle.jvm.toolchain.JavaToolchainService
import javax.inject.Inject
```

### 8b. Add helper classes (before the `buildscript` block)
```groovy
abstract class BallerinaExecHelper {
    @Inject abstract ExecOperations getExecOperations()
}

abstract class PatchBallerinaScriptsTask extends DefaultTask {
    @Inject abstract JavaToolchainService getJavaToolchainService()

    @TaskAction
    void patch() {
        def launcher = javaToolchainService.launcherFor { spec ->
            spec.languageVersion.set(JavaLanguageVersion.of(25))
        }.get()
        def java25Home = launcher.executablePath.asFile.parentFile.parentFile.absolutePath

        def binDirs = [
            project.layout.buildDirectory.dir("jballerina-tools-${project.ballerinaLangVersion}/bin").get().asFile,
            new File("${project.rootDir}/target/ballerina-runtime/bin")
        ]
        binDirs.each { binDir ->
            if (binDir.exists()) {
                binDir.eachFile { file ->
                    file.setExecutable(true)
                    if (!file.name.endsWith('.bat') && !file.name.endsWith('.cmd')) {
                        def original = file.text
                        def lines = original.split('\n').toList()
                        // Remove flag removed in Java 25
                        lines = lines.findAll { !it.contains('--sun-misc-unsafe-memory-access=allow') }
                        // Inject JAVA_HOME so the bal script picks up Java 25
                        def shebangIdx = lines.findIndexOf { it.startsWith('#!') }
                        if (shebangIdx >= 0) {
                            lines.add(shebangIdx + 1, "export JAVA_HOME='${java25Home}'")
                        }
                        def patched = lines.join('\n') + '\n'
                        if (patched != original) { file.text = patched }
                    }
                }
            }
        }
    }
}
```

### 8c. Add mavenLocal() to buildscript repositories
```groovy
buildscript {
    repositories {
        mavenLocal()   // add before existing entries
        maven { ... }
    }
    ...
}
```

### 8d. Fix commitTomlFiles task
Replace `project.exec {` with the injected helper:
```groovy
task commitTomlFiles {
    def execHelper = project.objects.newInstance(BallerinaExecHelper)
    doLast {
        execHelper.execOperations.exec {
            ignoreExitValue true
            if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                commandLine 'cmd', '/c', "git commit -m \"[Automated] Update native jar versions in toml files\" Ballerina.toml Dependencies.toml"
            } else {
                commandLine 'sh', '-c', "git commit -m \"[Automated] Update native jar versions in toml files\" Ballerina.toml Dependencies.toml"
            }
        }
    }
}
```
Keep the original commit message and file list exactly as they were — only replace `project.exec` with `execHelper.execOperations.exec`.

### 8e. Add patchBallerinaScripts task and wire it
```groovy
task patchBallerinaScripts(type: PatchBallerinaScriptsTask) {
    dependsOn 'unpackJballerinaTools'
}

// Wire to BOTH build and test — this is REQUIRED:
// - build.dependsOn: ensures patching during `./gradlew build`
// - test.dependsOn:  ensures patching when test runs separately (e.g. split CI invocation:
//   first `./gradlew build -x test`, then `./gradlew test` — unpackJballerinaTools re-runs
//   in the second invocation and the bal binary loses its execute bit and the patched script
//   unless test also depends on patchBallerinaScripts)
build.dependsOn patchBallerinaScripts
test.dependsOn patchBallerinaScripts
```

If the module also has a `copyStdlibs` task, additionally wire
`copyStdlibs.dependsOn patchBallerinaScripts` for correct ordering, but the two lines above
are the required baseline for all modules.

---

## Step 9 — Fix Project.exec() in other build.gradle files

Gradle 9 removed `Project.exec()`. In Groovy build scripts, a bare `exec { }` inside a task body
also delegates to `project.exec` — so you need to find both forms:

```bash
grep -rn "project\.exec\|[^a-zA-Z]exec {" --include="*.gradle" .
```

Apply the same ExecOperations pattern (Steps 8a–8d) for each file found (common in
`ballerina-tests/build.gradle`, `integration-tests/build.gradle`, `examples/build.gradle`). Use
a unique class name per file to avoid collisions (e.g. `BallerinaTestsExecHelper`,
`IntegrationTestsExecHelper`, `ExamplesExecHelper`).

---

## Step 10 — Update Ballerina.toml files

Only update TOML files that have a `[platform.java21]` section:
```bash
grep -rl "platform.java21" --include="*.toml" .
```

For each match:
- `[platform.java21]` → `[platform.java25]`
- `[[platform.java21.dependency]]` → `[[platform.java25.dependency]]`
- Update `distribution = "..."` in the `[package]` section to `"2201.14.0-20260527-050400-74f7e6bf"` where present

---

## Step 11 — SpotBugs exclusion files

SpotBugs 4.9.x (bundled in plugin ≥ 6.2.0) introduces detectors that surface pre-existing issues.
Add exclusions to the relevant `spotbugs-exclude.xml` files.

First, find all exclude files:
```bash
find . -name "spotbugs-exclude.xml" -not -path "*/build/*"
```

**For the native module's exclude file** (handles main source analysis), add before `</FindBugsFilter>`:
```xml
<!-- Pre-existing issues surfaced by SpotBugs 4.9.x (bundled in plugin >= 6.2.0) -->
<Match>
    <BugCode name="THROWS"/>
</Match>
<Match>
    <BugCode name="AT"/>
</Match>
<Match>
    <BugCode name="USELESS_STRING"/>
</Match>
```

**For compiler-plugin-tests exclude file** (if it exists), add before `</FindBugsFilter>`:
```xml
<!-- Pre-existing issues surfaced by SpotBugs 4.9.x (bundled in plugin >= 6.2.0) -->
<Match>
    <BugCode name="THROWS"/>
</Match>
```

Some modules use a single shared `spotbugs-exclude.xml` (e.g. at repo root or `build-config/`).
In that case, add all three exclusions (`THROWS`, `AT`, `USELESS_STRING`) to that single file.

**Additional: DM (DM_DEFAULT_CHARSET)** — Some modules that do String/byte conversion without an
explicit charset will also trigger a `DM` finding. If the build fails with SpotBugs reporting
`DM_DEFAULT_CHARSET`, add this exclusion as well:
```xml
<Match>
    <BugCode name="DM"/>
</Match>
```

---

## Step 12 — Update CI workflow

Check which type of CI workflow the repo uses:

```bash
cat .github/workflows/pull-request.yml
```

### Repos using the shared template (most stdlib modules)

If the workflow calls the shared template, update it from `@main` to `@java-25-migration`:

```yaml
# Before
uses: ballerina-platform/ballerina-library/.github/workflows/pull-request-build-template.yml@main

# After
uses: ballerina-platform/ballerina-library/.github/workflows/pull-request-build-template.yml@java-25-migration
```

The `@java-25-migration` branch installs JDK 25 via `actions/setup-java@v4`, which is required for
the Gradle Java 25 toolchain to resolve on CI runners (they don't have JDK 25 pre-installed).

### Repos with a custom inline workflow (e.g. module-ballerina-observe, module-ballerinai-observe)

If the workflow does NOT use the shared template and has inline build steps, update all Java
version references in **every job** (ubuntu-build, windows-build, ubuntu-build-without-native-tests, etc.):

```yaml
# Before
- name: Set up JDK 21
  uses: actions/setup-java@v2   # or v3
  with:
    distribution: 'adopt'
    java-version: 21

# After
- name: Set up JDK 25
  uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: 25
```

---

## Step 13 — Build verification (local, full)

Run the **full build including tests** locally and verify it passes before committing:

```bash
./gradlew build
```

**If it fails, diagnose by error message:**

| Error | Cause | Fix |
|---|---|---|
| `Unsupported class file major version 69` (SpotBugs) | SpotBugs too old | Verify `6.5.1` is set in gradle.properties |
| `Error while instrumenting ... with JaCoCo ... Unsupported class file major version 69` | JaCoCo too old | Set `jacocoVersion=0.8.13` in `gradle.properties`; also check for hardcoded `toolVersion = "0.8.10"` in individual `build.gradle` files |
| `key 'java25' not supported in schema 'platform'` | Old lang version | Verify `2201.14.0-20260527-050400-74f7e6bf` is in local Maven |
| `Could not find method exec()` | Missed a `project.exec` or bare `exec {}` call | `grep -rn "project\.exec\|[^a-zA-Z]exec {" --include="*.gradle" .` |
| `Permission denied` on bal binary | patchBallerinaScripts not wired | Check `build.dependsOn patchBallerinaScripts` and `test.dependsOn patchBallerinaScripts` |
| `--sun-misc-unsafe-memory-access=allow` unrecognized | bal script not patched yet (task didn't run on prior extraction) | Manually patch extracted scripts and re-run |
| SpotBugs exit code 1 or 3 | New bug findings | Read `*/build/reports/spotbugs/main.txt`, add specific `<BugCode>` exclusions |
| `Cannot add task 'build'` | task build conflict | Apply Step 5a fix |
| `sourceCompatibility` / `targetCompatibility` conflict | Toolchain + explicit compat set together | Apply Step 7 fix |

Iterate until the full build (including tests) is clean **locally** before committing or pushing.

---

## Step 14 — Commit

Stage all modified files (build.gradle files, gradle.properties, TOML files, spotbugs XMLs,
gradle-wrapper.properties, settings.gradle, .github/workflows/pull-request.yml). Do NOT add a Co-Authored-By line.

```bash
git add <all modified files>
git commit -m "Migrate to Gradle 9.5.1, Java 25, and Ballerina Lang 2201.14.0-20260527-050400-74f7e6bf

- Upgrade Gradle wrapper to 9.5.1
- Replace com.gradle.enterprise with com.gradle.develocity plugin
- Upgrade net.researchgate.release to 3.1.0 for Gradle 9 compatibility
- Replace all deprecated buildDir references with layout.buildDirectory
- Replace Project.exec() calls with ExecOperations injection pattern
- Remove deprecated sourceCompatibility/targetCompatibility (replaced by toolchain)
- Add Java 25 toolchain to all Java subprojects
- Upgrade Ballerina Gradle plugin to 4.0.0 (Java 25 + Gradle 9.5.1 compatible)
- Update ballerinaLangVersion to 2201.14.0-20260527-050400-74f7e6bf
- Update all platform.java21 TOML sections to platform.java25
- Add patchBallerinaScripts task to fix bal binary permissions and remove
  --sun-misc-unsafe-memory-access=allow flag (removed in Java 25)
- Upgrade SpotBugs Gradle plugin to 6.5.1 for Java 25 class file support
- Add SpotBugs exclusions for THROWS/AT/USELESS_STRING detectors introduced
  in SpotBugs 4.9.x (bundled in plugin >= 6.2.0)
- Update CI workflow to use pull-request-build-template.yml@java-25-migration"
```

---

## Step 15 — Push and create PR

### Detect the default branch
```bash
git remote show upstream | grep 'HEAD branch' | awk '{print $NF}'
```

### Push ONLY to upstream java-25-migration
```bash
git push upstream java-25-migration
```

> **Important:** This is the only upstream branch you may push to. Do not push to master, main,
> or any other upstream branch.

### Create PR
```bash
# Get the repo name from the upstream remote URL
REPO=$(git remote get-url upstream | sed 's|.*github.com/||' | sed 's|\.git||')
DEFAULT_BRANCH=$(git remote show upstream | grep 'HEAD branch' | awk '{print $NF}')

gh pr create \
  --repo "$REPO" \
  --head java-25-migration \
  --base "$DEFAULT_BRANCH" \
  --title "Migrate to Gradle 9.5.1 and Java 25" \
  --body "## Summary

- **Gradle 9.5.1**: Upgrade wrapper; replace removed \`buildDir\` API with \`layout.buildDirectory\`; replace \`Project.exec()\` with \`ExecOperations\` injection; migrate from \`com.gradle.enterprise\` to \`com.gradle.develocity\`; upgrade \`net.researchgate.release\` to 3.1.0
- **Java 25**: Add Java 25 toolchain to all subprojects; upgrade Ballerina Gradle plugin to 4.0.0 and \`ballerinaLangVersion\` to \`2201.14.0-20260527-050400-74f7e6bf\`; update all \`[platform.java21]\` TOML sections to \`[platform.java25]\`; add \`patchBallerinaScripts\` task to remove the \`--sun-misc-unsafe-memory-access=allow\` JVM flag (removed in Java 25) from the extracted \`bal\` binary after unpack; wire \`test.dependsOn patchBallerinaScripts\` to ensure patching during split CI builds
- **SpotBugs 6.5.1**: Upgrade for Java 25 class file support (requires SpotBugs 4.9.x / ASM 9.7+); add exclusions for \`THROWS\`, \`AT\`, and \`USELESS_STRING\` detectors introduced in SpotBugs 4.9.x
- **JaCoCo 0.8.13**: Upgrade for Java 25 class file instrumentation support
- **CI workflow**: Update to \`pull-request-build-template.yml@java-25-migration\` for JDK 25 runner support

## Test plan
- [ ] \`./gradlew build\` passes green locally (full build including tests)
- [ ] \`.bala\` artifact is created as \`*-java25-*.bala\`
- [ ] SpotBugs passes on native module and compiler-plugin-tests
- [ ] CI passes on both Ubuntu and Windows"
```
