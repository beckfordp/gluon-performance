package gluon.perf

import java.util.SplittableRandom

class TraceparentSuite extends munit.FunSuite {

  private val W3cFormat = "00-[0-9a-f]{32}-[0-9a-f]{16}-01".r

  test("generate yields a sampled W3C traceparent header") {
    val header = Traceparent.generate(new SplittableRandom(42)).header
    assert(W3cFormat.matches(header), header)
  }

  test("ids are never all-zero, even from a zero-only random source") {
    val zeros = new java.util.random.RandomGenerator {
      def nextLong(): Long = 0L
    }
    val tp = Traceparent.generate(zeros)
    assertNotEquals(tp.traceId, "0" * 32)
    assertNotEquals(tp.spanId, "0" * 16)
  }

  test("successive generates are unique") {
    val random = new SplittableRandom(7)
    val traceIds = List.fill(1000)(Traceparent.generate(random).traceId)
    assertEquals(traceIds.distinct.size, 1000)
  }

  test("parse round-trips a generated header and rejects malformed ones") {
    val tp = Traceparent.generate(new SplittableRandom(1))
    assertEquals(Traceparent.parse(tp.header), Some(tp))
    assertEquals(Traceparent.parse("00-abc-def-01"), None)
    assertEquals(Traceparent.parse(s"00-${"0" * 32}-${"1" * 16}-01"), None)
  }
}
