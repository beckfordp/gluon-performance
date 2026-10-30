package gluon.perf

import io.gatling.core.Predef.*
import io.gatling.core.structure.ScenarioBuilder

/** PERF-1.3: `GET /health/ready` on every service, one user, zero failures.
  *
  * Proves the harness reaches every service with trace-linked requests; no
  * load. Run against port-forwards (`scripts/port-forward.sh up`) or, from
  * Performance 2, in-cluster.
  */
class SmokeSimulation extends Simulation {

  private val config = GluonConfig.loadOrThrow()

  private val scn: ScenarioBuilder =
    scenario("smoke").exec(
      Service.all.map { service =>
        Traced.get(
          s"ready ${service.name}",
          s"${config.baseUrl(service).value}/health/ready"
        )
      }
    )

  setUp(scn.inject(atOnceUsers(1)))
    .protocols(Protocols.http)
    .assertions(global.failedRequests.count.is(0L))
}
