use Mix.Releases.Config,
    default_release: :default,
    default_environment: :dev

environment :dev do
  set(cookie: :https_light)
end

environment :prod do
  set(cookie: :https_light)
end

release :https_light do
  set version: current_version(:https_light)
  plugin Shoehorn
  if System.get_env("NERVES_SYSTEM") do
    set dev_mode: false
    set include_src: false
    set include_erts: System.get_env("ERL_LIB_DIR")
    set include_system_libs: System.get_env("ERL_SYSTEM_LIB_DIR")
    set vm_args: "rel/vm.args"
  end
end

