data "yandex_compute_image" "ubuntu-master" {
  family = var.vm_image_master
}

resource "yandex_compute_instance" "master-nodes" {
  name        = "${var.master_node_names}-${count.index + 1}"
  hostname    = "${var.master_node_names}-${count.index + 1}"
  zone        = "${var.subnet-zones[count.index]}"
  metadata    = var.ssh_root_key
  platform_id = var.nodes_platform_id
  count = var.master_nodes_size
  allow_stopping_for_update = true
  labels = {
    index = "${var.master_node_names}-${count.index + 1}"
  }

  resources {
    cores         = var.nodes_resources.master_node_resources.cores
    memory        = var.nodes_resources.master_node_resources.memory
    core_fraction = var.nodes_resources.master_node_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-master.image_id
      type     = var.boot_disk_master_nodes[0].type
      size     = var.boot_disk_master_nodes[0].size
    }
  }

  scheduling_policy {
    preemptible = var.vm_nat
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnets[count.index].id
    nat       = var.vm_nat
  }
}
