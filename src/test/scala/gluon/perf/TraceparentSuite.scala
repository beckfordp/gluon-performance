package gluon.perf

class TraceparentSuite extends munit.FunSuite {

  private val W3cFormat = "00-[0-9a-f]{32}-[0-9a-f]{16}-01".r

  test("fromBits yields a sampled W3C traceparent header") {
    val header = Traceparent.fromBits(42L, -7L, 123456789L).header
    assert(W3cFormat.matches(header), header)
  }

  test("bits are encoded as zero-padded lowercase hex, two's complement") {
    assertEquals(
      Traceparent.fromBits(0L, 1L, 255L),
      Traceparent("0" * 31 + "1", "00000000000000ff")
    )
    assertEquals(
      Traceparent.fromBits(-1L, -1L, -1L),
      Traceparent("f" * 32, "f" * 16)
    )
  }

  test("ids are never all-zero, even from all-zero bits") {
    val tp = Traceparent.fromBits(0L, 0L, 0L)
    assertNotEquals(tp.traceId, "0" * 32)
    assertNotEquals(tp.spanId, "0" * 16)
  }

  test("parse round-trips a built header and rejects malformed ones") {
    val tp = Traceparent.fromBits(1L, 2L, 3L)
    assertEquals(Traceparent.parse(tp.header), Some(tp))
    assertEquals(Traceparent.parse("00-abc-def-01"), None)
    assertEquals(Traceparent.parse(s"00-${"0" * 32}-${"1" * 16}-01"), None)
  }
}
