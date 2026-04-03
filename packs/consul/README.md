# consul — Nomad Pack

Deploy a production-ready **HashiCorp Consul** cluster on a Nomad cluster using
[Nomad Pack](https://github.com/hashicorp/nomad-pack).

---

## Features

| Feature | Default |
|---|---|
| Consul **server**, **client**, or **both** (system) mode | `server` |
| Configurable server count & bootstrap-expect | 3 |
| Docker-based deployment with capability hardening | ✅ |
| Host-volume data persistence | ✅ |
| TLS (mTLS) for API & RPC | opt-in |
| ACL system | opt-in |
| Gossip encryption | opt-in |
| Consul Connect / service mesh | opt-in |
| Consul UI | enabled |
| Vault integration | opt-in |
| Rolling updates with auto-revert | ✅ |
| Extra env-var injection | ✅ |

---

## Requirements

| Tool | Minimum version |
|---|---|
| HashiCorp Nomad | 1.6+ |
| Nomad Pack | 0.1.2+ |
| Docker driver enabled on all Nomad nodes | — |
| Host volume `consul-data` declared in Nomad client config | — |

### Declare the host volume on every Nomad client

```hcl
# /etc/nomad.d/client.hcl  (each agent)
client {
  host_volume "consul-data" {
    path      = "/opt/consul/data"
    read_only = false
  }
}
```

Create the data and config directories on each node:

```bash
sudo mkdir -p /opt/consul/{data,config,tls}
sudo chown -R nobody:nobody /opt/consul/data
```

---

## Quick Start

### 1. Add the registry (once)

```bash
nomad-pack registry add my-registry github.com/your-org/nomad-pack-registry
```

### 2. Deploy with defaults (3-server cluster, no TLS/ACLs)

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var="datacenters=[\"dc1\"]" \
  --var="retry_join=[\"10.0.0.1\",\"10.0.0.2\",\"10.0.0.3\"]"
```

### 3. Deploy in "both" mode (system job — server+client on every node)

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var="consul_mode=both" \
  --var="retry_join=[\"provider=aws tag_key=consul tag_value=server\"]"
```

---

## Variable Reference

See [`variables.hcl`](./variables.hcl) for the full list with types, defaults,
and descriptions. Key variables:

### Job settings

| Variable | Type | Default | Description |
|---|---|---|---|
| `job_name` | string | `consul` | Nomad job name |
| `datacenters` | list(string) | `["dc1"]` | Target datacenters |
| `namespace` | string | `default` | Nomad namespace |
| `region` | string | `global` | Nomad region |

### Consul mode & image

| Variable | Type | Default | Description |
|---|---|---|---|
| `consul_mode` | string | `server` | `server`, `client`, or `both` |
| `consul_image` | string | `hashicorp/consul:1.18` | Docker image |
| `server_count` | number | `3` | Server replica count |
| `bootstrap_expect` | number | `3` | Bootstrap quorum |

### Ports

| Variable | Default | Description |
|---|---|---|
| `http_port` | `8500` | HTTP API |
| `https_port` | `8501` | HTTPS API (TLS) |
| `grpc_port` | `8502` | gRPC / Envoy xDS |
| `serf_lan_port` | `8301` | LAN gossip |
| `serf_wan_port` | `8302` | WAN gossip |
| `server_rpc_port` | `8300` | Server RPC |
| `dns_port` | `8600` | DNS |

### Security (all opt-in)

| Variable | Type | Default |
|---|---|---|
| `tls_enabled` | bool | `false` |
| `acl_enabled` | bool | `false` |
| `acl_default_policy` | string | `deny` |
| `encrypt_enabled` | bool | `false` |
| `encrypt_key` | string | `""` |
| `connect_enabled` | bool | `false` |

---

## Production Deployment Examples

### Full-security cluster (TLS + ACLs + encryption)

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var="consul_image=hashicorp/consul:1.18" \
  --var="server_count=3" \
  --var="bootstrap_expect=3" \
  --var="retry_join=[\"10.0.1.10\",\"10.0.1.11\",\"10.0.1.12\"]" \
  --var="tls_enabled=true" \
  --var="acl_enabled=true" \
  --var="acl_default_policy=deny" \
  --var="encrypt_enabled=true" \
  --var="encrypt_key=<base64-key-from-consul-keygen>" \
  --var="connect_enabled=true" \
  --var="ui_enabled=true" \
  --var="memory=1024" \
  --var="memory_max=2048"
```

### Cloud auto-join (AWS)

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var='retry_join=["provider=aws tag_key=Role tag_value=consul-server region=us-east-1"]'
```

### Cloud auto-join (GCP)

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var='retry_join=["provider=gce project_name=my-project tag_value=consul-server"]'
```

### Override using a var-file

Create `my-consul.vars.hcl`:

```hcl
job_name        = "consul-prod"
datacenters     = ["us-east-1", "us-west-2"]
server_count    = 5
bootstrap_expect = 5
consul_image    = "hashicorp/consul:1.18"
tls_enabled     = true
acl_enabled     = true
encrypt_enabled = true
encrypt_key     = "your-key-here"
connect_enabled = true
log_level       = "WARN"
memory          = 1024
memory_max      = 2048
retry_join      = ["10.0.1.10","10.0.1.11","10.0.1.12","10.0.1.13","10.0.1.14"]
```

```bash
nomad-pack run consul \
  --registry=my-registry \
  --var-file=my-consul.vars.hcl
```

---

## Pushing to a Private Nomad Pack Registry

A Nomad Pack registry is just a GitHub (or self-hosted Git) repository with a
specific structure. Follow these steps:

### 1. Create the registry repository

```
nomad-pack-registry/
└── packs/
    └── consul/
        ├── metadata.hcl
        ├── variables.hcl
        └── templates/
            ├── consul.nomad.tpl
            └── _helpers.tpl
```

### 2. Commit and push

```bash
git init nomad-pack-registry
cd nomad-pack-registry
# copy consul/ pack directory here under packs/
git add .
git commit -m "feat: add consul pack v0.1.0"
git remote add origin https://github.com/your-org/nomad-pack-registry.git
git push -u origin main
```

### 3. Tag a release (optional but recommended)

```bash
git tag v0.1.0
git push origin v0.1.0
```

### 4. Register and use

```bash
# Add the registry locally
nomad-pack registry add my-registry github.com/your-org/nomad-pack-registry

# List available packs
nomad-pack registry list

# Render (dry-run)
nomad-pack render consul --registry=my-registry

# Run
nomad-pack run consul --registry=my-registry

# Plan (like terraform plan)
nomad-pack plan consul --registry=my-registry

# Destroy
nomad-pack destroy consul --registry=my-registry
```

---

## Generating Gossip Encryption Key

```bash
# Using Consul binary
consul keygen

# Using OpenSSL (if consul binary unavailable)
openssl rand -base64 32
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Allocation fails with "volume not found" | Declare `consul-data` host volume in Nomad client config |
| `bind: permission denied` on port 8500 | Ensure `cap_add = ["NET_BIND_SERVICE"]` or use ports > 1024 |
| Consul not forming cluster | Check `retry_join` addresses; confirm ports 8300-8302 are open |
| UI not reachable | Set `ui_enabled=true` and confirm `http_port` is not firewalled |
| TLS handshake errors | Verify CA, cert, and key files exist on the host at configured paths |

---

## License

Mozilla Public License 2.0 — same as HashiCorp Consul.
