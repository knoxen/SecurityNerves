use Mix.Config

config :nerves_network, :default,
  wlan0: [
    ssid: "StopNet",
    psk: "lightson",
    key_mgmt: :"WPA-PSK"
  ]
