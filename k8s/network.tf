resource "yandex_vpc_network" "diplom-network" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "subnets" {
  count          = 3
  name           = "subnet-${var.subnet-zones[count.index]}"
  zone           = "${var.subnet-zones[count.index]}"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = [ "${var.cidr.stage[count.index]}" ]
}
