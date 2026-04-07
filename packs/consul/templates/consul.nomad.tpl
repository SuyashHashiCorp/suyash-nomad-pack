job [[ template "job_name" . ]] {
  [[ template "region" . ]]
  datacenters = [[ var "datacenters" . | toStringList ]]
  type = "service"

  group "app" {
    count = [[ var "count" . ]]

    network {
      port "http" {
        to = 8500
      }
    }

    [[ if var "register_service" . ]]
    service {
      name = "[[ var "service_name" . ]]"
      tags = [[ var "service_tags" . | toStringList ]]
      provider = "nomad"
      port = "http"
#      check {
#        name     = "alive"
#        type     = "http"
#        path     = "/"
#        interval = "10s"
#        timeout  = "2s"
#      }
    }
    [[ end ]]

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/consul:1.22"
        ports = ["http"]
        command = "/bin/consul"
        args = ["agent", "-dev"]
      }

      env {
        MESSAGE = [[ var "message" . | quote ]]
      }
    }
  }
}
