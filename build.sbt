val scala2Version = "2.13.18"

val gatlingVersion = "3.16.0"
val munitVersion = "1.3.6"

// Gatling publishes no Scala 3 artifacts (see conductor/tech-stack.md), so this
// harness is Scala 2.13 with -Xsource:3. Gatling deps are Compile-scoped because
// src/main's shared Protocols helper uses the DSL;
// simulations live in src/test, where gatling-sbt's Gatling config finds them.
lazy val root = project
  .in(file("."))
  .enablePlugins(GatlingPlugin)
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
    )
  )
