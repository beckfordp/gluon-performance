package gluon.perf

/** A named load profile (PLAN.md PERF-7.4). Injection shapes land in
  * Performance 7; Performance 1 only needs the names, so `PERF_PROFILE` can be
  * validated.
  */
sealed abstract class Profile(val name: String)
    extends Product
    with Serializable

object Profile {
  case object Smoke extends Profile("smoke")
  case object Baseline extends Profile("baseline")
  case object DecemberRamp extends Profile("december-ramp")
  case object BlackFridaySpike extends Profile("black-friday-spike")
  case object LastPostingDay extends Profile("last-posting-day")
  case object Soak extends Profile("soak")

  val all: List[Profile] =
    List(Smoke, Baseline, DecemberRamp, BlackFridaySpike, LastPostingDay, Soak)

  def fromName(name: String): Option[Profile] = all.find(_.name == name)
}
