## Is Security on Your Nerves?

This repo contains the demo app used for Paul Rogers' __*Is Security on Your Nerves*__ presentation. Without having seen that presentation examining this codebase could be a bit of a challenge. It is not intended to be a stand alone tutorial.

A much simpler demo of the SRPC security framework can be found on GitHub at [SrpcWorld](https://github.com/knoxen/SrpcWorld).

#### Presentation

The [HTML](SecurityNerves.html) version contains animations.

The [PDF](SecurityNerves.pdf) version is static.

#### Running the applications

Running the applications in this repo on an iPad and RPi3 devices requires bit of setup overhead. I'm posting primarily for code inspection. If you do attempt to actually run the code and need assistance, please do contact me <paul@knoxen.com>.

The iOS app is designed for an iPad mini and looks a bit odd for other view classes.

There are three Nerves apps, *http_light*, *https_light* and *srpc_light*.

##### Run Locally
The Nerves apps can be run locally using

```bash
> MIX_TARGET=host iex -S mix
```

There will be some warnings regarding missing dependencies that are needed for true RPi3 execution.

To access locally run instances of the *\*_light* applications, change the `useStaticHost` variable in `StopNet.swift` to `true`:

```swift
  static var useStaticHost = true
```

You cannot access the *https_light* application from the iOS Simulator. To access from an actual iOS device requires the device be jailbroken and have [SSL Kill Switch](https://github.com/nabla-c0d3/ssl-kill-switch2) installed. Again, this repo is primarily for code inspection and not really for running the code "live" like I do in the presentation.

