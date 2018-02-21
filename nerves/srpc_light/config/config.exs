use Mix.Config

config :srpc_srv, srpc_handler: SrpcLight.SrpcHandler

config :srpc_light, :srpc_file,
  path: [
    device: "/opt",
    host: "rootfs_overlay/opt"
  ],
  name: "server.srpc"

config :stop_light, :cred_file,
  path: [
    device: "/root",
    host: "/tmp/root"
  ],
  name: "StopNetSrpc.cred"

config :stop_light, :network,
  mdns_domain: "srpc.local",
  node_name: "light"

config :stop_light, :elli,
  port: 4003,
  stack: [
    {SrpcElli.ElliHandler, []},
    {StopLight.Elli.StatusHandler, []},
    {HttpLight.Elli.LoginHandler, []},
    {StopLight.Elli.LightsHandler, []}
  ]

config :kncache,
  caches: [
    srpc_exch: 30,
    srpc_nonce: 35,
    srpc_conn: 300,
    srpc_reg: 3600,
    user_data: 300
  ]

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
#   fwup_conf: "config/fwup.conf"

config :shoehorn,
  init: [:nerves_runtime],
  app: Mix.Project.config()[:app]

import_config "../../stop_light/config/config.exs"
