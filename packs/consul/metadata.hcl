app {
  url = "https://developer.hashicorp.com/consul"
}

pack {
  name        = "consul"
  description = "Deploys a Consul server cluster on Nomad using nomad-pack"
  version     = "0.1.0"
}

# Optional dependency information. This block can be repeated.

# dependency "demo_dep" {
#   alias  = "demo_dep"
#   source = "git://source.git/packs/demo_dep"
# }

# Declared dependencies will be downloaded from their source
# using "nomad-pack vendor deps" and added to ./deps directory.

# Dependencies in active development can by symlinked in
# the ./deps directory

# Example dependency source values:
# - "git::https://github.com/org-name/repo-name.git//packs/demo_dep"
# - "git@github.com:org-name/repo-name.git/packs/demo_dep"
