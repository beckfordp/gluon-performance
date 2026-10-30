val scala2Version = "2.13.18"

val gatlingVersion = "3.16.0"
val munitVersion = "1.3.6"

// Gatling publishes no Scala 3 artifacts (see conductor/tech-stack.md), so this
// harness is Scala 2.13 with -Xsource:3. Gatling deps are Compile-scoped because
// src/main's shared Protocols helper uses the DSL;
// simulations live in src/test, where gatling-sbt's Gatling config finds them.
lazy val root = project
  .in(file("."))
  .enablePlugins(GatlingPlugin, JavaAppPackaging, DockerPlugin)
  .settings(
    name := "gluon-performance",
    scalaVersion := scala2Version,
    version := "0.1.0",
    scalacOptions ++= Seq(
      "-deprecation",
      "-feature",
      "-unchecked",
      "-Xlint",
      "-Wunused:_",
      "-Xsource:3",
      "-Xsource-features:case-apply-copy-access"
    ),
    libraryDependencies ++= Seq(
      "io.gatling.highcharts" % "gatling-charts-highcharts" % gatlingVersion,
      "io.gatling" % "gatling-test-framework" % gatlingVersion,
      "org.scalameta" %% "munit" % munitVersion % Test
    ),
    // In-cluster image (PERF-2.1). Simulations stay in src/test, so the Test
    // jar (classes + logback-test.xml) and Test-only dependency jars are added
    // to the staged lib/ and launcher classpath; the launcher runs Gatling's
    // own main rather than an app main.
    Compile / mainClass := Some("io.gatling.app.Gatling"),
    Compile / discoveredMainClasses := Seq.empty,
    // native-packager collects every packaged artifact of this project, which
    // gatling-sbt extends with its Gatling Enterprise package (fails: no
    // simulations in src/it). Only the main jar belongs in the image.
    projectDependencyArtifacts := Seq(
      Attributed
        .blank((Compile / packageBin).value)
        .put(moduleID.key, projectID.value)
        .put(artifact.key, (Compile / packageBin / artifact).value)
    ),
    Universal / mappings ++= {
      val compileJars = (Compile / dependencyClasspath).value.map(_.data).toSet
      val testOnlyJars =
        (Test / dependencyClasspath).value.map(_.data).filterNot(compileJars)
          .filter(f => f.isFile && f.getName.endsWith(".jar"))
      ((Test / packageBin).value -> s"lib/${name.value}-tests.jar") +:
        testOnlyJars.map(f => f -> s"lib/${f.getName}")
    },
    scriptClasspath ++= {
      val compileJars = (Compile / dependencyClasspath).value.map(_.data).toSet
      s"${name.value}-tests.jar" +:
        (Test / dependencyClasspath).value.map(_.data).filterNot(compileJars)
          .filter(f => f.isFile && f.getName.endsWith(".jar"))
          .map(_.getName)
    },
    // The JVM flags gatling-sbt passes to forked runs (`show Gatling/javaOptions`),
    // minus -Xmx (heap is sized from the pod limit via JAVA_OPTS
    // -XX:MaxRAMPercentage) and JDK 23+ only flags (image is JDK 21).
    Universal / javaOptions ++= Seq(
      "-XX:+HeapDumpOnOutOfMemoryError",
      "-XX:MaxInlineLevel=20",
      "-XX:MaxTrivialSize=12",
      "--enable-native-access=ALL-UNNAMED",
      "--add-opens=java.base/java.lang=ALL-UNNAMED",
      "--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED"
    ).map("-J" + _),
    dockerBaseImage := "eclipse-temurin:21-jre",
    Docker / packageName := "gluon-performance",
    dockerUpdateLatest := true,
    dockerEntrypoint := Seq("/opt/docker/bin/run-simulation.sh")
  )
