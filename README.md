# suyash-nomad-pack

A collection of custom [Nomad Packs](https://developer.hashicorp.com/nomad/tools/nomad-pack) for day-to-day Nomad cluster operations, databases, and infrastructure management.

## Prerequisites

- [Nomad Pack](https://github.com/hashicorp/nomad-pack) installed
- A running Nomad cluster (1.3+ for native service registry)
- Nomad Enterprise license (required for `nomad_snapshot_agent` only)

## Add this registry

```bash
nomad-pack registry add suyash-nomad-pack https://github.com/SuyashHashiCorp/suyash-nomad-pack.git
```

Verify it was added:

```bash
nomad-pack registry list
```

---

## Available Packs

### 🔧 nomad_debug_bundle

Periodically runs `nomad operator debug` on a cron schedule and saves the
debug archive to a host directory automatically.

No more manually collecting debug bundles when issues arise — just point
support to the output directory.

| Detail | Value |
|---|---|
| Job type | `batch` + `periodic` |
| Driver | `raw_exec` |
| Default schedule | Every 12 hours |
| Output | `.tar.gz` archive on host |

---

### 📸 nomad_snapshot_agent

Deploys the **Nomad Enterprise** `operator snapshot agent` as a long-running
service job with support for four storage backends.

| Detail | Value |
|---|---|
| Job type | `service` |
| Driver | `raw_exec` |
| Edition | Nomad Enterprise only |
| Default schedule | Every 24 hours |
| Backends | Local, AWS S3, Azure Blob, Google Cloud Storage |

---

### 🍃 mongodb

Deploys a MongoDB instance using the Docker driver with persistent storage,
Nomad native service registration, and configurable authentication.

| Detail | Value |
|---|---|
| Job type | `service` |
| Driver | `docker` |
| Default version | MongoDB 7.0 |
| Service registry | Nomad native (`provider = "nomad"`) |
| Storage | Host volume |

---

## Pack versions

| Pack | Version | Nomad Edition |
|---|---|---|
| `nomad_debug_bundle` | 0.1.0 | OSS + Enterprise |
| `nomad_snapshot_agent` | 0.1.0 | Enterprise only |
| `mongodb` | 0.1.0 | OSS + Enterprise |

---

## Common requirements

### raw_exec driver

The `nomad_debug_bundle` and `nomad_snapshot_agent` packs
all use the `raw_exec` driver. Make sure it is enabled on your Nomad clients:

```hcl
# /etc/nomad.d/client.hcl
plugin "raw_exec" {
  config {
    enabled = true
  }
}
```

### Nomad binary on client hosts

`raw_exec` packs invoke the `nomad` binary directly on the host. Ensure it
exists at the configured path (default: `usr/local/bin/nomad`) on every
client node that may run these jobs.

### ACL tokens

If your cluster has ACLs enabled:

| Pack | Required capabilities |
|---|---|
| `nomad_debug_bundle` | `node:read`, `agent:read`, `operator:read`, `list-jobs`, `agent:write` |
| `nomad_snapshot_agent` | `operator:write` or `operator:snapshot-save` + `operator:license-read` |
| `mongodb` | n/a |

---

## Contributing

Found a bug or want to improve a pack? PRs are welcome.

---

## Resources

- [Nomad Pack documentation](https://developer.hashicorp.com/nomad/tools/nomad-pack)
- [Nomad Pack community registry](https://github.com/hashicorp/nomad-pack-community-registry)
