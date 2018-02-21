use Mix.Config

config :shoehorn,
  init: [:nerves_runtime],
  app: Mix.Project.config()[:app]

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
#   fwup_conf: "config/fwup.conf"

config :stop_light, :pem_file,
  path: [
    device: "/opt",
    host: "rootfs_overlay/opt"
  ],
  key: "HttpsLightKey.pem",
  cert: "HttpsLightCert.pem"

config :stop_light, :cred_file,
  path: [
    device: "/root",
    host: "/tmp/root"
  ],
  name: "StopNetHttps.cred"

config :stop_light, :network,
  mdns_domain: "https.local",
  node_name: "light"

config :stop_light, :elli,
  port: 4002,
  stack: [
    {StopLight.Elli.StatusHandler, []},
    {HttpLight.Elli.LoginHandler, []},
    {StopLight.Elli.LightsHandler, []}
  ]

import_config "../../stop_light/config/config.exs"
