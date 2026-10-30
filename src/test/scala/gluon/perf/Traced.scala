package gluon.perf

import java.util.concurrent.ThreadLocalRandom

import io.gatling.core.Predef.*
import io.gatling.core.structure.ChainBuilder
import io.gatling.http.Predef.*
import org.slf4j.LoggerFactory

/** Trace-linked requests (PERF-1.4): each request gets a fresh `traceparent`,
  * and its trace id is logged with the request name and status (logger
  * `gluon.perf.trace`, see logback-test.xml) so a slow request in the Gatling
  * report can be found in Tempo.
  *
  * Simulation-side DSL glue over the pure [[Traceparent]] and [[TraceLog]];
  * exercised by the smoke run rather than unit tests.
  */
object Traced {
  private val logger = LoggerFactory.getLogger("gluon.perf.trace")
  private val StatusKey = "gluon.status"

  def get(name: String, url: String): ChainBuilder =
    exec(
      _.set(
        Traceparent.HeaderName,
        Traceparent.generate(ThreadLocalRandom.current()).header
      )
    )
      .exec(
        http(name)
          .get(url)
          .header(Traceparent.HeaderName, s"#{${Traceparent.HeaderName}}")
          // saveAs first so the status is logged even when the 2xx check fails
          .check(status.saveAs(StatusKey), status.in(200 to 299))
      )
      .exec { session =>
        logger.info(
          TraceLog.line(
            name,
            session(StatusKey).asOption[Int],
            session(Traceparent.HeaderName).asOption[String]
          )
        )
        session.remove(StatusKey)
      }
}
