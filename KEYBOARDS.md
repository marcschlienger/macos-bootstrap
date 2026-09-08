# Keyboard setup on macOS

The keyboard layout has two implementations:

- QMK runs on the Keychron V3 Max ANSI and Q3 ANSI knob keyboards, including
  when they are used with an iPad or a computer without Kanata.
- Kanata runs only on the MacBook's internal keyboard. Its device include list
  prevents the QMK and Kanata mappings from being applied to a Keychron at the
  same time.

Both produce one-shot Caps/Control and Shift keys. QMK gives the Keychrons this
complete bottom-row order:

    Alt  Super  Control  Space  Control  Super  Right-Alt  Fn

Kanata maps the MacBook's function row explicitly: the keys alone provide
brightness, Mission Control, Spotlight, Dictation, Do Not Disturb, media, and
volume controls. Holding Fn produces F1--F12, while tapping Fn retains the
Globe action. It maps the available modifier positions to the corresponding
Alt, Super, and Control order. To the right of Space, right Command becomes
one-shot right Control and right Option remains ordinary Option:

    Space  Control  Option

Super/Command remains available on the left side.

The dotfiles repository is the source of the Kanata configuration. The
personal `qmk` repository is the source of the two QMK keymaps and the factory
firmware recovery files.

## Kanata

The regular bootstrap installs Kanata and stows its dotfiles package. To run
only the relevant steps:

```sh
./bootstrap basic-configuration install-system-tools
kanata --version
kanata --check --cfg "$HOME/.config/kanata/kanata.kbd"
```

### Install and activate the virtual keyboard

Kanata needs Karabiner's DriverKit VirtualHIDDevice even though it does not
need Karabiner-Elements. For Kanata 1.12, install the VirtualHIDDevice 6.2.0
package from its [release page](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/tag/v6.2.0).
Check Kanata's compatibility notes before upgrading either component.

Activate the installed driver:

```sh
sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager forceActivate
```

Then enable `org.pqrs.Karabiner-DriverKit-VirtualHIDDevice` in **System
Settings > General > Login Items & Extensions > Driver Extensions**. A reboot
may be required. Verify the result:

```sh
systemextensionsctl list
```

The driver entry must say `[activated enabled]`.

### Grant both privacy permissions

Under **System Settings > Privacy & Security**, add the installed Kanata
executable to both of these lists and enable it:

- **Input Monitoring**
- **Device Control and Data Access** on macOS 27, named **Accessibility** on
  earlier macOS releases

Use **+**, press **Command-Shift-G**, and open `/opt/homebrew/bin/`. If adding
the `kanata` symlink does not work, use `ls -l /opt/homebrew/bin/kanata` and add
its real target. Remove and re-add a stale entry after Homebrew replaces or
moves the binary. A terminal foreground test can additionally require that
terminal application's permissions; the root service still needs Kanata's
own entries.

### Install the boot services

The Dotfiles package supplies launchd property lists for the virtual-keyboard
helper and Kanata. They contain Marc's absolute Apple Silicon paths. Review
them before using them on another account or an Intel Mac.

```sh
cd ~/.dotfiles/kanata/.config/kanata/launchd
/opt/homebrew/bin/kanata --check --cfg "$HOME/.config/kanata/kanata.kbd"
plutil -lint dev.kanata.kanata.plist org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist

sudo install -o root -g wheel -m 0644 org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
sudo install -o root -g wheel -m 0644 dev.kanata.kanata.plist /Library/LaunchDaemons/dev.kanata.kanata.plist

sudo launchctl enable system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon
sudo launchctl enable system/dev.kanata.kanata
sudo launchctl bootstrap system /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.kanata.plist
```

Do not install the standalone VirtualHIDDevice daemon if Karabiner-Elements is
already running its copy. Validate and restart Kanata after a configuration
change:

```sh
/opt/homebrew/bin/kanata --check --cfg "$HOME/.config/kanata/kanata.kbd" && \
  sudo launchctl kickstart -k system/dev.kanata.kanata
```

Verify the service, its output backend, and the device filter:

```sh
sudo launchctl print system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon
sudo launchctl print system/dev.kanata.kanata
sudo tail -n 40 /var/log/karabiner-vhid-daemon.log /var/log/kanata.log
kanata --list
```

The configuration must process `Apple Internal Keyboard / Trackpad`, not the
Keychrons. The detailed recovery commands are in
`~/.dotfiles/kanata/README.md`.

## QMK and the Keychrons

QMK needs to be installed on only one computer. Firmware built on macOS also
runs when the keyboard is attached to Debian or iPadOS.

Homebrew may require explicit trust for the QMK and AVR taps:

```sh
brew tap osx-cross/avr
brew tap qmk/qmk
brew trust --tap osx-cross/avr
brew trust --tap qmk/qmk
brew install qmk/qmk/qmk
qmk --version
```

A warning that a prerelease macOS version is unsupported is not by itself a
failed installation. `qmk doctor` must still compile a test and find the ARM
and AVR tools.

Clone the personal source and the Keychron firmware tree, then copy the
tracked keymaps into the vendor checkout:

```sh
git clone git@github.com:marcschlienger/qmk.git ~/Repos/qmk
git clone --branch 2025q3 --recurse-submodules https://github.com/Keychron/qmk_firmware.git ~/Repos/qmk/keychron-qmk
cd ~/Repos/qmk/keychron-qmk
qmk setup -H "$PWD"

cp -R ../keymaps/keychron/v3_max/ansi_encoder/marc keyboards/keychron/v3_max/ansi_encoder/keymaps/
cp -R ../keymaps/keychron/q3/ansi_encoder/marc keyboards/keychron/q3/ansi_encoder/keymaps/

qmk doctor
qmk compile -kb keychron/v3_max/ansi_encoder -km marc
qmk compile -kb keychron/q3/ansi_encoder -km marc
```

The Keychron fork is deliberately not the personal Git remote. Consequently,
`qmk doctor` may warn that the official repository is not configured as an
`upstream` remote; that does not invalidate a successful compile. Compilation
also reports `VIA_INSECURE is enabled` because the personal keymaps preserve
VIA support. Treat host-side VIA tools as trusted software.

### Flash one keyboard at a time

Both boards expose the same generic STM32 DFU identity. Disconnect the other
Keychron before entering bootloader mode so the wrong firmware cannot be sent
to it. Put the selected keyboard in Cable mode, connect it directly by USB,
and start its matching command:

```sh
qmk flash -kb keychron/v3_max/ansi_encoder -km marc
qmk flash -kb keychron/q3/ansi_encoder -km marc
```

When the command waits for the bootloader, unplug that keyboard, hold Escape,
reconnect it, and release Escape after about two seconds. The physical reset
button below the space bar is the alternative. Keep the cable connected until
`dfu-util` reports `File downloaded successfully` and exits successfully.

After flashing, confirm that the keyboard reappears normally with
`kanata --list`. VIA can retain an old dynamic layout across a firmware flash.
If the new layout is not active, hold **Fn + J + Z** for about four seconds.
The new keymap puts Fn on the far-right modifier; during the first migration,
the retained layout may still put it on the key labelled Fn.

Test Caps, both Shift keys, every bottom-row modifier, Fn, the encoder, the
Mac/Windows switch positions, USB, wireless modes on the V3 Max, and an iPad.
Factory firmware and its checksums are recorded in the personal QMK
repository. Do not flash Bluetooth or receiver firmware to change a keymap.
