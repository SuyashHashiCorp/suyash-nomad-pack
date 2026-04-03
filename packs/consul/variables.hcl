# =============================================================================
# consul/variables.hcl
# All configurable inputs for the Consul Nomad Pack
# =============================================================================

# -----------------------------------------------------------------------------
# Job-level settings
# -----------------------------------------------------------------------------

variable "job_name" {
  description = "Name of the Nomad job."
  type        = string
  default     = "consul"
}

variable "datacenters" {
  description = "List of datacenters to deploy Consul into."
  type        = list(string)
  default     = ["dc1"]
}

variable "namespace" {
  description = "Nomad namespace to run the job in."
  type        = string
  default     = "default"
}

variable "region" {
  description = "Nomad region to run the job in."
  type        = string
  default     = "global"
}

# -----------------------------------------------------------------------------
# Consul mode
# -----------------------------------------------------------------------------

variable "consul_mode" {
  description = "Consul agent mode: 'server', 'client', or 'both' (server+client on each node via system job)."
  type        = string
  default     = "server"
}

# -----------------------------------------------------------------------------
# Image & version
# -----------------------------------------------------------------------------

variable "consul_image" {
  description = "Docker image for Consul."
  type        = string
  default     = "hashicorp/consul:1.18"
}

variable "image_pull_policy" {
  description = "Docker image pull policy: always, missing, or never."
  type        = string
  default     = "missing"
}

# -----------------------------------------------------------------------------
# Cluster sizing
# -----------------------------------------------------------------------------

variable "server_count" {
  description = "Number of Consul server replicas (use 3 or 5 for production)."
  type        = number
  default     = 3
}

variable "bootstrap_expect" {
  description = "Number of servers to wait for before bootstrapping. Should equal server_count."
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# Ports
# -----------------------------------------------------------------------------

variable "http_port" {
  description = "Consul HTTP API port."
  type        = number
  default     = 8500
}

variable "https_port" {
  description = "Consul HTTPS API port (used when TLS is enabled)."
  type        = number
  default     = 8501
}

variable "grpc_port" {
  description = "Consul gRPC port (used for xDS / Envoy)."
  type        = number
  default     = 8502
}

variable "serf_lan_port" {
  description = "Consul Serf LAN gossip port."
  type        = number
  default     = 8301
}

variable "serf_wan_port" {
  description = "Consul Serf WAN gossip port."
  type        = number
  default     = 8302
}

variable "server_rpc_port" {
  description = "Consul server RPC port."
  type        = number
  default     = 8300
}

variable "dns_port" {
  description = "Consul DNS port."
  type        = number
  default     = 8600
}

# -----------------------------------------------------------------------------
# Resources
# -----------------------------------------------------------------------------

variable "cpu" {
  description = "CPU allocation in MHz."
  type        = number
  default     = 500
}

variable "memory" {
  description = "Memory allocation in MB."
  type        = number
  default     = 512
}

variable "memory_max" {
  description = "Maximum memory in MB (burst). Set to 0 to disable."
  type        = number
  default     = 1024
}

# -----------------------------------------------------------------------------
# Storage / volumes
# -----------------------------------------------------------------------------

variable "data_dir" {
  description = "Host path for Consul data directory (bind-mounted into the container)."
  type        = string
  default     = "/opt/consul/data"
}

variable "config_dir" {
  description = "Host path for extra Consul config files."
  type        = string
  default     = "/opt/consul/config"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "network_mode" {
  description = "Nomad network mode: host, bridge, or cni/<name>."
  type        = string
  default     = "host"
}

# -----------------------------------------------------------------------------
# TLS
# -----------------------------------------------------------------------------

variable "tls_enabled" {
  description = "Enable TLS for Consul API and RPC."
  type        = bool
  default     = false
}

variable "tls_ca_file" {
  description = "Path to the CA certificate file on the host (required when tls_enabled = true)."
  type        = string
  default     = "/opt/consul/tls/ca.pem"
}

variable "tls_cert_file" {
  description = "Path to the server certificate file on the host."
  type        = string
  default     = "/opt/consul/tls/server.pem"
}

variable "tls_key_file" {
  description = "Path to the server private key file on the host."
  type        = string
  default     = "/opt/consul/tls/server-key.pem"
}

# -----------------------------------------------------------------------------
# ACLs
# -----------------------------------------------------------------------------

variable "acl_enabled" {
  description = "Enable Consul ACL system."
  type        = bool
  default     = false
}

variable "acl_default_policy" {
  description = "Default ACL policy when ACLs are enabled: allow or deny."
  type        = string
  default     = "deny"
}

variable "acl_down_policy" {
  description = "ACL down policy: allow, deny, extend-cache, or async-cache."
  type        = string
  default     = "extend-cache"
}

# -----------------------------------------------------------------------------
# Gossip encryption
# -----------------------------------------------------------------------------

variable "encrypt_enabled" {
  description = "Enable Consul gossip encryption."
  type        = bool
  default     = false
}

variable "encrypt_key" {
  description = "Base64-encoded 32-byte gossip encryption key (generate with: consul keygen)."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Connect / service mesh
# -----------------------------------------------------------------------------

variable "connect_enabled" {
  description = "Enable Consul Connect service mesh."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------

variable "ui_enabled" {
  description = "Enable the Consul web UI."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "log_level" {
  description = "Consul log level: TRACE, DEBUG, INFO, WARN, ERR."
  type        = string
  default     = "INFO"
}

# -----------------------------------------------------------------------------
# Retry-join (auto-join)
# -----------------------------------------------------------------------------

variable "retry_join" {
  description = "List of addresses or cloud auto-join strings Consul uses to find other servers."
  type        = list(string)
  default     = []
}

variable "retry_join_wan" {
  description = "List of WAN addresses for joining remote datacenters."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Vault integration
# -----------------------------------------------------------------------------

variable "vault_enabled" {
  description = "Enable Vault integration (Nomad Vault stanza)."
  type        = bool
  default     = false
}

variable "vault_role" {
  description = "Vault role to use when vault_enabled = true."
  type        = string
  default     = "consul-server"
}

# -----------------------------------------------------------------------------
# Constraints & affinities
# -----------------------------------------------------------------------------

variable "node_pool" {
  description = "Target a specific Nomad node pool (leave empty to target all)."
  type        = string
  default     = ""
}

variable "node_class" {
  description = "Constrain to a specific Nomad node class (leave empty to skip)."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Update strategy
# -----------------------------------------------------------------------------

variable "update_max_parallel" {
  description = "Max parallel updates."
  type        = number
  default     = 1
}

variable "update_min_healthy_time" {
  description = "Minimum time a task must be healthy before continuing a rolling update."
  type        = string
  default     = "30s"
}

variable "update_healthy_deadline" {
  description = "Deadline for a deployment to be healthy."
  type        = string
  default     = "5m"
}

variable "update_auto_revert" {
  description = "Automatically revert to the last stable deployment on failure."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Extra environment variables
# -----------------------------------------------------------------------------

variable "extra_envvars" {
  description = "Additional environment variables injected into the Consul container."
  type        = map(string)
  default     = {}
}
