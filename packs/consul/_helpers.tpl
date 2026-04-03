[[- /*
  consul/templates/_helpers.tpl
  Reusable template helpers for the Consul Nomad Pack.
*/ -]]

[[- /*
  "job_name" returns the job name variable.
*/ -]]
[[ define "job_name" ]]
[[- var "job_name" . -]]
[[ end ]]

[[- /*
  "consul_image" returns the full Docker image reference.
*/ -]]
[[ define "consul_image" ]]
[[- var "consul_image" . -]]
[[ end ]]

[[- /*
  "retry_join_args" renders -retry-join flags from the list.
*/ -]]
[[ define "retry_join_args" ]]
[[- range $addr := var "retry_join" . ]]
          "-retry-join=[[ $addr ]]",
[[- end ]]
[[ end ]]
