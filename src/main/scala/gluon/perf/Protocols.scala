package gluon.perf

import io.gatling.core.Predef.*
import io.gatling.core.config.GatlingConfiguration
import io.gatling.http.protocol.HttpProtocolBuilder

/** The one `HttpProtocol` every simulation shares. */
object Protocols {

  /** No base URL: Gluon is eight services, so each request uses its service's
    * absolute URL from [[GluonConfig.baseUrl]]. Warm-up and caching are off so
    * every measured request reaches a service.
    */
  def http(implicit configuration: GatlingConfiguration): HttpProtocolBuilder =
    io.gatling.http.Predef.http
      .acceptHeader("application/json")
      .contentTypeHeader("application/json")
      .userAgentHeader("gluon-performance")
      .disableWarmUp
      .disableCaching
}
