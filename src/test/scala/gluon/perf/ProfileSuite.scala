package gluon.perf

class ProfileSuite extends munit.FunSuite {

  test("every profile round-trips through its name") {
    Profile.all.foreach(p => assertEquals(Profile.fromName(p.name), Some(p)))
  }

  test("unknown names are rejected") {
    assertEquals(Profile.fromName("boxing-day"), None)
  }
}
