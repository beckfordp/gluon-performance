package gluon.perf

class TraceLogSuite extends munit.FunSuite {

  private val traceId = "4bf92f3577b34da6a3ce929d0e0e4736"
  private val header = s"00-$traceId-00f067aa0ba902b7-01"

  test("line carries request name, status and trace id as key=value pairs") {
    assertEquals(
      TraceLog.line("ready order-service", Some(200), Some(header)),
      s"""trace request="ready order-service" status=200 trace_id=$traceId"""
    )
  }

  test("missing status (connection failure) or traceparent is shown as '-'") {
    assertEquals(
      TraceLog.line("ready cart-service", None, None),
      """trace request="ready cart-service" status=- trace_id=-"""
    )
  }
}
