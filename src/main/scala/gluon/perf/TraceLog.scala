package gluon.perf

/** The per-request log line linking a Gatling request to its trace. */
object TraceLog {

  /** `trace request="<name>" status=<code> trace_id=<id>`, with `-` for a
    * missing status (no response, e.g. connection refused) or traceparent.
    */
  def line(
      request: String,
      status: Option[Int],
      traceparent: Option[String]
  ): String = {
    val traceId = traceparent.flatMap(Traceparent.parse).map(_.traceId)
    s"""trace request="$request" status=${status.fold("-")(
        _.toString
      )} trace_id=${traceId.getOrElse("-")}"""
  }
}
