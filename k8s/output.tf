output "master-nodes" {
  value = flatten([
    [for i in yandex_compute_instance.master-nodes : {
      name = i.name
      ip_external   = i.network_interface[0].nat_ip_address
      ip_internal = i.network_interface[0].ip_address
    }]
  ])
}

output "worker-nodes" {
  value = flatten([
    [for i in yandex_compute_instance.worker-nodes : {
      name = i.name
      ip_external   = i.network_interface[0].nat_ip_address
      ip_internal = i.network_interface[0].ip_address
    }]
  ])
}

output "grafana-address" {
  value = yandex_lb_network_load_balancer.nlb-grafana.listener.*.external_address_spec[0].*.address
}

output "web-app-address" {
  value = yandex_lb_network_load_balancer.nlb-web-app.listener.*.external_address_spec[0].*.address
}
