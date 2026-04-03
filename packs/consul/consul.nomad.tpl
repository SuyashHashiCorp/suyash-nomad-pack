[[- /*
  consul/templates/consul.nomad.tpl
  Main Nomad job definition for running Consul on a Nomad cluster.
*/ -]]

job [[ template "job_name" . | quote ]] {
  region      = [[ var "region" . | quote ]]
  datacenters = [[ var "datacenters" . | toStringList ]]
  namespace   = [[ var "namespace" . | quote ]]

  [[- if eq (var "consul_mode" .) "both" ]]
  # System scheduler: runs one allocation on every eligible Nomad node.
  type = "system"
  [[- else ]]
  type = "service"
  [[- end ]]

  meta {
    consul_pack_version = "0.1.0"
    consul_mode         = [[ var "consul_mode" . | quote ]]
  }

  # ---------------------------------------------------------------------------
  # Constraints
  # ---------------------------------------------------------------------------

  [[- if ne (var "node_class" .) "" ]]
  constraint {
    attribute = "${node.class}"
    value     = [[ var "node_class" . | quote ]]
  }
  [[- end ]]

  [[- if ne (var "node_pool" .) "" ]]
  node_pool = [[ var "node_pool" . | quote ]]
  [[- end ]]

  # ---------------------------------------------------------------------------
  # Update policy
  # ---------------------------------------------------------------------------
  update {
    max_parallel      = [[ var "update_max_parallel" . ]]
    min_healthy_time  = [[ var "update_min_healthy_time" . | quote ]]
    healthy_deadline  = [[ var "update_healthy_deadline" . | quote ]]
    auto_revert       = [[ var "update_auto_revert" . ]]
    canary            = 0
  }

  # ---------------------------------------------------------------------------
  # Vault integration (optional)
  # ---------------------------------------------------------------------------
  [[- if var "vault_enabled" . ]]
  vault {
    policies = [[[ var "vault_role" . | quote ]]]
    change_mode = "restart"
  }
  [[- end ]]

  # ---------------------------------------------------------------------------
  # Server group
  # ---------------------------------------------------------------------------
  [[- if or (eq (var "consul_mode" .) "server") (eq (var "consul_mode" .) "both") ]]
  group "consul-servers" {
    count = [[ if eq (var "consul_mode" .) "both" ]]1[[ else ]][[ var "server_count" . ]][[ end ]]

    [[- if eq (var "consul_mode" .) "server" ]]
    # Spread servers evenly across nodes
    spread {
      attribute = "${node.unique.id}"
    }
    [[- end ]]

    restart {
      attempts = 5
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    network {
      mode = [[ var "network_mode" . | quote ]]

      port "http" {
        static = [[ var "http_port" . ]]
        to     = [[ var "http_port" . ]]
      }

      [[- if var "tls_enabled" . ]]
      port "https" {
        static = [[ var "https_port" . ]]
        to     = [[ var "https_port" . ]]
      }
      [[- end ]]

      port "grpc" {
        static = [[ var "grpc_port" . ]]
        to     = [[ var "grpc_port" . ]]
      }

      port "serf_lan" {
        static = [[ var "serf_lan_port" . ]]
        to     = [[ var "serf_lan_port" . ]]
      }

      port "serf_wan" {
        static = [[ var "serf_wan_port" . ]]
        to     = [[ var "serf_wan_port" . ]]
      }

      port "server_rpc" {
        static = [[ var "server_rpc_port" . ]]
        to     = [[ var "server_rpc_port" . ]]
      }

      port "dns" {
        static = [[ var "dns_port" . ]]
        to     = [[ var "dns_port" . ]]
      }
    }

    volume "consul-data" {
      type      = "host"
      read_only = false
      source    = "consul-data"
    }

    service {
      name     = "consul-server"
      port     = "http"
      tags     = ["consul", "server", "infrastructure"]

      check {
        name     = "consul-server-health"
        type     = "http"
        path     = "/v1/status/leader"
        interval = "15s"
        timeout  = "5s"
      }
    }

    task "consul-server" {
      driver = "docker"

      config {
        image      = [[ var "consul_image" . | quote ]]
        force_pull = [[ if eq (var "image_pull_policy" .) "always" ]]true[[ else ]]false[[ end ]]

        args = [
          "agent",
          "-server",
          "-bootstrap-expect=[[ var "bootstrap_expect" . ]]",
          "-data-dir=/consul/data",
          "-config-dir=/consul/config",
          "-client=0.0.0.0",
          "-bind=0.0.0.0",
          "-advertise={{ GetInterfaceIP \"eth0\" }}",
          "-ui=[[ var "ui_enabled" . ]]",
          "-log-level=[[ var "log_level" . ]]",
          "-datacenter=${NOMAD_DC}",
          [[- range $addr := var "retry_join" . ]]
          "-retry-join=[[ $addr ]]",
          [[- end ]]
          [[- range $addr := var "retry_join_wan" . ]]
          "-retry-join-wan=[[ $addr ]]",
          [[- end ]]
          [[- if var "connect_enabled" . ]]
          "-connect",
          [[- end ]]
          [[- if var "encrypt_enabled" . ]]
          "-encrypt=[[ var "encrypt_key" . ]]",
          [[- end ]]
        ]

        volumes = [
          "[[ var "config_dir" . ]]:/consul/config",
        ]

        ports = [
          "http",
          [[- if var "tls_enabled" . ]]"https",[[- end ]]
          "grpc",
          "serf_lan",
          "serf_wan",
          "server_rpc",
          "dns",
        ]

        # Drop all Linux capabilities except what Consul needs
        cap_drop = ["ALL"]
        cap_add  = ["NET_BIND_SERVICE", "IPC_LOCK"]
      }

      volume_mount {
        volume      = "consul-data"
        destination = "/consul/data"
        read_only   = false
      }

      # TLS certificates (bind-mounted from host)
      [[- if var "tls_enabled" . ]]
      template {
        destination = "/consul/config/tls.hcl"
        data        = <<-EOT
          tls {
            defaults {
              ca_file   = "/consul/tls/ca.pem"
              cert_file = "/consul/tls/server.pem"
              key_file  = "/consul/tls/server-key.pem"
              verify_incoming        = true
              verify_outgoing        = true
              verify_server_hostname = true
            }
            internal_rpc { verify_server_hostname = true }
          }
        EOT
        change_mode   = "restart"
        perms         = "0640"
      }
      [[- end ]]

      # ACL configuration
      [[- if var "acl_enabled" . ]]
      template {
        destination = "/consul/config/acl.hcl"
        data        = <<-EOT
          acl {
            enabled        = true
            default_policy = "[[ var "acl_default_policy" . ]]"
            down_policy    = "[[ var "acl_down_policy" . ]]"
            tokens {}
          }
        EOT
        change_mode = "restart"
        perms       = "0640"
      }
      [[- end ]]

      # Connect / service mesh
      [[- if var "connect_enabled" . ]]
      template {
        destination = "/consul/config/connect.hcl"
        data        = <<-EOT
          connect { enabled = true }
          ports    { grpc = [[ var "grpc_port" . ]] }
        EOT
        change_mode = "restart"
        perms       = "0640"
      }
      [[- end ]]

      env {
        [[- range $k, $v := var "extra_envvars" . ]]
        [[ $k ]] = [[ $v | quote ]]
        [[- end ]]
      }

      resources {
        cpu        = [[ var "cpu" . ]]
        memory     = [[ var "memory" . ]]
        [[- if gt (var "memory_max" .) 0 ]]
        memory_max = [[ var "memory_max" . ]]
        [[- end ]]
      }

      kill_timeout = "30s"
    }
  }
  [[- end ]]

  # ---------------------------------------------------------------------------
  # Client group (only created when mode = "client" or "both")
  # ---------------------------------------------------------------------------
  [[- if or (eq (var "consul_mode" .) "client") (eq (var "consul_mode" .) "both") ]]
  group "consul-clients" {
    [[- if eq (var "consul_mode" .) "client" ]]
    count = 1
    [[- end ]]

    restart {
      attempts = 5
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    network {
      mode = [[ var "network_mode" . | quote ]]

      port "http_client" {
        static = [[ var "http_port" . ]]
        to     = [[ var "http_port" . ]]
      }

      port "serf_lan_client" {
        static = [[ var "serf_lan_port" . ]]
        to     = [[ var "serf_lan_port" . ]]
      }

      port "dns_client" {
        static = [[ var "dns_port" . ]]
        to     = [[ var "dns_port" . ]]
      }
    }

    service {
      name = "consul-client"
      port = "http_client"
      tags = ["consul", "client"]

      check {
        name     = "consul-client-health"
        type     = "http"
        path     = "/v1/agent/self"
        interval = "15s"
        timeout  = "5s"
      }
    }

    task "consul-client" {
      driver = "docker"

      config {
        image      = [[ var "consul_image" . | quote ]]
        force_pull = [[ if eq (var "image_pull_policy" .) "always" ]]true[[ else ]]false[[ end ]]

        args = [
          "agent",
          "-data-dir=/consul/data",
          "-config-dir=/consul/config",
          "-client=0.0.0.0",
          "-bind=0.0.0.0",
          "-advertise={{ GetInterfaceIP \"eth0\" }}",
          "-log-level=[[ var "log_level" . ]]",
          "-datacenter=${NOMAD_DC}",
          [[- range $addr := var "retry_join" . ]]
          "-retry-join=[[ $addr ]]",
          [[- end ]]
        ]

        volumes = [
          "[[ var "config_dir" . ]]:/consul/config",
        ]

        ports = ["http_client", "serf_lan_client", "dns_client"]

        cap_drop = ["ALL"]
        cap_add  = ["NET_BIND_SERVICE"]
      }

      env {
        [[- range $k, $v := var "extra_envvars" . ]]
        [[ $k ]] = [[ $v | quote ]]
        [[- end ]]
      }

      resources {
        cpu        = [[ var "cpu" . ]]
        memory     = [[ var "memory" . ]]
        [[- if gt (var "memory_max" .) 0 ]]
        memory_max = [[ var "memory_max" . ]]
        [[- end ]]
      }

      kill_timeout = "15s"
    }
  }
  [[- end ]]
}
