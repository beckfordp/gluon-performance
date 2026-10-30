addSbtPlugin("io.gatling" % "gatling-sbt" % "4.19.2")
addSbtPlugin("org.scoverage" % "sbt-scoverage" % "2.4.4")
addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.2")
// Packages the harness (incl. Test-scoped simulations) as a Docker image for in-cluster runs.
addSbtPlugin("com.github.sbt" % "sbt-native-packager" % "1.11.1")
