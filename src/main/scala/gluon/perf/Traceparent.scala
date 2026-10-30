package gluon.perf

/** A sampled W3C Trace Context `traceparent` (version 00, flags 01).
  *
  * Gatling's built-in OpenTelemetry tracing is Enterprise-only (ADR 0019), so
  * the harness generates its own: each request starts a new trace that the
  * services join, and the trace id is logged so a slow request in the Gatling
  * report can be found in Tempo.
  */
final case class Traceparent(traceId: String, spanId: String) {
  def header: String = s"00-$traceId-$spanId-01"
}

object Traceparent {
  val HeaderName = "traceparent"

  private val Format = "00-([0-9a-f]{32})-([0-9a-f]{16})-01".r
  private val ZeroTrace = "0" * 32
  private val ZeroSpan = "0" * 16

  /** Builds ids from caller-supplied random bits (pure: randomness is drawn at
    * the Gatling session boundary, see `Traced`). The low bit of each id is
    * forced on, so an id is never all-zero (W3C marks those invalid); 127
    * random bits per trace id is still ample.
    */
  def fromBits(traceHigh: Long, traceLow: Long, span: Long): Traceparent =
    Traceparent(f"$traceHigh%016x${traceLow | 1L}%016x", f"${span | 1L}%016x")

  def parse(header: String): Option[Traceparent] = header match {
    case Format(traceId, spanId)
        if traceId != ZeroTrace && spanId != ZeroSpan =>
      Some(Traceparent(traceId, spanId))
    case _ => None
  }
}
