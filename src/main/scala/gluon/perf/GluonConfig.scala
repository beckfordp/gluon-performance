package gluon.perf

import java.net.{URI, URISyntaxException}

/** An absolute http(s) base URL with no trailing slash. */
final case class BaseUrl private (value: String)

object BaseUrl {
  def parse(raw: String): Option[BaseUrl] = {
    val trimmed = raw.trim.stripSuffix("/")
    val uri =
      try Some(new URI(trimmed))
      catch { case _: URISyntaxException => None }
    uri
      .filter(uri => Set("http", "https").contains(uri.getScheme))
      .filter(uri => Option(uri.getHost).exists(_.nonEmpty))
      .map(_ => new BaseUrl(trimmed))
  }

  def localhost(port: Int): BaseUrl = new BaseUrl(s"http://localhost:$port")
}

sealed trait ConfigError extends Product with Serializable {
  def message: String
}

object ConfigError {
  final case class InvalidUrl(key: String, value: String) extends ConfigError {
    def message: String = s"$key: '$value' is not an absolute http(s) URL"
  }
  final case class UnknownProfile(value: String) extends ConfigError {
    def message: String =
      s"PERF_PROFILE: unknown profile '$value' (expected one of ${Profile.all.map(_.name).mkString(", ")})"
  }
}

/** Harness configuration read from env vars: `<SERVICE>_URL` per service
  * (default: its local port-forward port) and `PERF_PROFILE` (default `smoke`).
  */
final case class GluonConfig(urls: Map[Service, BaseUrl], profile: Profile) {
  def baseUrl(service: Service): BaseUrl =
    urls.getOrElse(service, BaseUrl.localhost(service.defaultPort))
}

object GluonConfig {
  val ProfileKey = "PERF_PROFILE"

  /** Parses every key, accumulating all errors rather than stopping at the
    * first.
    */
  def fromEnv(
      env: Map[String, String]
  ): Either[::[ConfigError], GluonConfig] = {
    val urls: List[Either[ConfigError, (Service, BaseUrl)]] = Service.all.map {
      s =>
        val key = s"${s.envPrefix}_URL"
        env.get(key) match {
          case None      => Right(s -> BaseUrl.localhost(s.defaultPort))
          case Some(raw) =>
            BaseUrl
              .parse(raw)
              .map(s -> _)
              .toRight(ConfigError.InvalidUrl(key, raw))
        }
    }
    val profile: Either[ConfigError, Profile] = env.get(ProfileKey) match {
      case None       => Right(Profile.Smoke)
      case Some(name) =>
        Profile.fromName(name).toRight(ConfigError.UnknownProfile(name))
    }
    val errors = urls.collect { case Left(e) =>
      e
    } ++ profile.left.toOption.toList
    errors match {
      case head :: tail => Left(::(head, tail))
      case Nil          =>
        profile
          .map(GluonConfig(urls.collect { case Right(u) => u }.toMap, _))
          .left
          .map(::(_, Nil))
    }
  }

  /** Simulation-boundary loader: Gatling simulations are imperative classes, so
    * invalid config fails fast with every error in one message.
    */
  def loadOrThrow(env: Map[String, String] = sys.env): GluonConfig =
    fromEnv(env).fold(
      errors =>
        throw new IllegalArgumentException(
          errors
            .map(_.message)
            .mkString("Invalid harness config:\n  ", "\n  ", "")
        ),
      identity
    )
}
