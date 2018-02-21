use Mix.Config

config :shoehorn,
  init: [:nerves_runtime],
  app: Mix.Project.config()[:app]

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
#   fwup_conf: "config/fwup.conf"

config :stop_light, :cred_file,
  path: [
    device: "/root",
    host: "/tmp/root"
  ],
  name: "StopNetHttp.cred"

config :stop_light, :network,
  mdns_domain: "http.local",
  node_name: "light"

config :stop_light, :elli,
  port: 4001,
  stack: [
    {StopLight.Elli.StatusHandler, []},
    {HttpLight.Elli.LoginHandler, []},
    {StopLight.Elli.LightsHandler, []}
  ]

import_config "../../stop_light/config/config.exs"
