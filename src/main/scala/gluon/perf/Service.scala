package gluon.perf

/** A Gluon service the harness can target.
  *
  * `envPrefix` names its `<PREFIX>_URL` override; `defaultPort` is its local
  * port-forward port, matching gshop's scripts where they overlap (order 18080,
  * payment 18081, inventory 18082, user 18083, fulfilment 18085).
  */
sealed abstract class Service(
    val name: String,
    val envPrefix: String,
    val defaultPort: Int
) extends Product
    with Serializable

object Service {
  case object Order extends Service("order-service", "ORDER", 18080)
  case object Payment extends Service("payment-service", "PAYMENT", 18081)
  case object Inventory extends Service("inventory-service", "INVENTORY", 18082)
  case object User extends Service("user-service", "USER", 18083)
  case object Catalog extends Service("catalog-service", "CATALOG", 18084)
  case object Fulfilment
      extends Service("fulfilment-service", "FULFILMENT", 18085)
  case object Cart extends Service("cart-service", "CART", 18086)
  case object Notification
      extends Service("notification-service", "NOTIFICATION", 18087)

  val all: List[Service] =
    List(
      Order,
      Payment,
      Inventory,
      User,
      Catalog,
      Fulfilment,
      Cart,
      Notification
    )
}
