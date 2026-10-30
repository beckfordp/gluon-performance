package gluon.perf

import io.gatling.core.config.GatlingConfiguration

class ProtocolsSuite extends munit.FunSuite {

  implicit private val configuration: GatlingConfiguration =
    GatlingConfiguration.loadForTest()

  private val protocol = Protocols.http.protocol

  test(
    "no warm-up request and no caching, so every measured request hits a service"
  ) {
    assertEquals(protocol.warmUpUrl, None)
    assertEquals(protocol.requestPart.cache, false)
  }

  test(
    "no base URL: requests use each service's absolute URL from GluonConfig"
  ) {
    assertEquals(protocol.baseUrls, Nil)
  }

  test(
    "JSON Accept and Content-Type plus a harness User-Agent on every request"
  ) {
    assertEquals(
      protocol.requestPart.headers.keySet.map(_.toString.toLowerCase),
      Set("accept", "content-type", "user-agent")
    )
  }
}
