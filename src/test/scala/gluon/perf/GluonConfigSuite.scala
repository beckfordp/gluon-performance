package gluon.perf

class GluonConfigSuite extends munit.FunSuite {

  test("empty env gives port-forward defaults and the smoke profile") {
    val config = GluonConfig.fromEnv(Map.empty)
    assertEquals(config.map(_.profile), Right(Profile.Smoke))
    assertEquals(
      config.map(_.baseUrl(Service.Order).value),
      Right("http://localhost:18080")
    )
    assertEquals(
      config.map(c =>
        Service.all.map(c.baseUrl(_).value.takeRight(5)).toSet.size
      ),
      Right(Service.all.size),
      "every service gets a distinct default port"
    )
  }

  test("<SERVICE>_URL overrides a service's base URL, trailing slash dropped") {
    val config =
      GluonConfig.fromEnv(Map("CATALOG_URL" -> "http://catalog-service:8080/"))
    assertEquals(
      config.map(_.baseUrl(Service.Catalog).value),
      Right("http://catalog-service:8080")
    )
  }

  test("PERF_PROFILE selects a profile by name") {
    assertEquals(
      GluonConfig
        .fromEnv(Map("PERF_PROFILE" -> "black-friday-spike"))
        .map(_.profile),
      Right(Profile.BlackFridaySpike)
    )
  }

  test("invalid URLs and unknown profile accumulate as errors") {
    val result = GluonConfig.fromEnv(
      Map(
        "ORDER_URL" -> "not a url",
        "CART_URL" -> "ftp://cart:21",
        "PERF_PROFILE" -> "boxing-day"
      )
    )
    assertEquals(
      result.left.map(_.toList.toSet),
      Left(
        Set[ConfigError](
          ConfigError.InvalidUrl("ORDER_URL", "not a url"),
          ConfigError.InvalidUrl("CART_URL", "ftp://cart:21"),
          ConfigError.UnknownProfile("boxing-day")
        )
      )
    )
  }

  test("loadOrThrow renders every error in one message") {
    val error = intercept[IllegalArgumentException](
      GluonConfig.loadOrThrow(Map("ORDER_URL" -> "x", "PERF_PROFILE" -> "y"))
    )
    assert(error.getMessage.contains("ORDER_URL"), error.getMessage)
    assert(error.getMessage.contains("y"), error.getMessage)
  }
}
