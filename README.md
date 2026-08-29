# macOS bootstrap

This repository configures a fresh macOS installation with personal system
preferences, Homebrew, dotfiles, fonts, command-line tools, development tools,
and desktop software. The executable shell scripts are the source of truth; no
Org-mode tangling or generated files are required.

GitHub is the canonical repository. A mirror is maintained on GitLab.

The scripts are designed to be rerunnable. Homebrew skips packages that are
already installed, existing Git repositories are retained, and existing files
are not silently overwritten.

## Requirements

- macOS on Apple Silicon or Intel
- an administrator account with internet access
- Git credentials for the configured dotfiles repository
- a backup of any existing configuration you want to preserve

Run the bootstrap as your normal user. Do **not** use `sudo`; Homebrew requests
administrator approval itself when macOS requires it.

## Quick start

```sh
git clone https://github.com/marcschlienger/macos-bootstrap.git
cd macos-bootstrap
./bootstrap
```

To see or run individual steps:

```sh
./bootstrap --list
./bootstrap basic-configuration install-shell-tools
```

Each installer can also be executed directly, for example:

```sh
./steps/install-emacs
```

## Configuration

Personal settings have sensible defaults and can be overridden for one run:

```sh
GIT_USER_NAME="Your Name" \
GIT_USER_EMAIL="you@example.com" \
DOTFILES_REPO="https://github.com/you/dotfiles" \
./bootstrap
```

Supported variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `GIT_USER_NAME` | `Marc Schlienger` | Global Git author name |
| `GIT_USER_EMAIL` | `marc.schlienger@posteo.de` | Global Git author email |
| `GIT_EDITOR` | `ec` | Global Git editor command |
| `DOTFILES_REPO` | `https://github.com/marcschlienger/dotfiles` | Dotfiles repository |
| `DOTFILES_DIR` | `~/.dotfiles` | Dotfiles checkout location |
| `ZSH_PLUGIN_DIR` | `~/.zsh/plugins` | Zsh plugin directory |
| `JDK_CASK` | `oracle-jdk` | JDK installed by the development stage |
| `COMPUTER_NAME` | `bleu` | Computer, Bonjour, and Unix host name |
| `SCREENSHOT_DIR` | `~/Pictures/Screenshots` | Screenshot storage directory |
| `TEXMF_SOURCE` | Personal Nextcloud TeX tree | Source for `~/Library/texmf` |

## Installation steps

### Basic configuration

- installs Homebrew when it is not already available
- configures the global Git identity, macOS Keychain credential helper, and
  editor
- installs GNU Stow
- clones the dotfiles repository and links the `emacs`, `kitty`, `neovim`,
  `tmux`, and `zsh` packages

An existing regular `~/.zshrc` is moved to a timestamped backup before Stow is
run. An unrelated existing symlink is left for Stow to report rather than being
silently replaced.

### macOS preferences

- sets the computer, Bonjour, and Unix host names to `bleu` by default; set
  `COMPUTER_NAME` to use another name for all three
- shows all filename extensions and the Finder path bar
- disables automatic smart-quote and smart-dash substitutions
- prevents `.DS_Store` files on network volumes
- saves screenshots as PNG files in `~/Pictures/Screenshots` by default; set
  `SCREENSHOT_DIR` to use another directory
- places an automatically hidden, non-magnifying Dock at the bottom with
  48-point icons and faster reveal animation
- uses the scale minimize effect, minimizes windows into their application
  icons, disables launch animation and recent apps, and retains running-app
  indicators
- keeps Spaces in their manually arranged order instead of rearranging them by
  most recent use

Finder and the Dock are restarted after their preferences are written. Other
preference changes take effect when the affected applications are next opened.

### Fonts

- Aporetic
- Fira Code Nerd Font
- Linux Libertine
- Symbols Only Nerd Font

The Aporetic cask installs all four families: sans, sans-mono, serif, and
serif-mono. The Emacs configuration prefers it because the faces are matched,
so `variable-pitch-mode` in Org and Denote buffers reads as one typeface
rather than a monospaced font paired with an unrelated serif.

The terminal uses Fira Code Nerd Font, and Emacs and the terminal differ on
purpose. Measured advance width per em: Fira Code 0.615, IBM Plex Mono
0.600, Aporetic 0.525, stock Iosevka 0.500. Iosevka is too crowded to read
comfortably in a terminal, and IBM Plex, though wide enough, has the
smallest x-height of the wide fonts and reads as faint.

Fira Code is the widest measured and takes the terminal. Aporetic keeps
Emacs, where its matched serif earns its place in prose buffers.

Aporetic carries no Nerd Font glyphs, so Emacs draws icons from Symbols Only
Nerd Font, which the Emacs configuration names explicitly.

The Debian bootstrap installs the same fonts from upstream's Git repository,
which publishes no release archives. The cask is occasionally a version
behind that source.

### Emacs

- taps `d12frosted/emacs-plus`
- installs the prebuilt `emacs-plus-app` cask, including Emacs Client
- installs Hunspell and `texlab`
- refreshes British English, American English, and German Hunspell dictionaries
  in `~/Library/Spelling`, and verifies that Hunspell discovers `en_US` and
  `de_DE`

`python-lsp-server` is deliberately not installed: the Python configuration
uses ty and Ruff instead. Emacs installs `flymake-ruff`, `ruff-format`, and
`swift-mode` itself. Apple's `/usr/bin/sourcekit-lsp` remains untouched; the
current lightweight Swift configuration does not use it.

Emacs Client connects to an existing Emacs server and automatically starts a
daemon when necessary, so a separate Homebrew service is unnecessary. Launch
`Emacs Client.app` from Finder, Spotlight, or the command line:

```sh
open -a "Emacs Client"
```

The equivalent terminal command creates a graphical frame and starts a daemon
when none is running:

```sh
emacsclient --create-frame --alternate-editor=''
```

To start the daemon explicitly before opening a client frame, run:

```sh
emacs --daemon
emacsclient --create-frame
```

The installed `emacs-plus-app` cask does not define a Homebrew service, so
`brew services start emacs-plus-app` is not available. The source-built
`emacs-plus` formula does define one; after deliberately replacing the cask
with that formula, it can be started immediately and at login with:

```sh
brew services start emacs-plus
```

When using a normally launched `Emacs.app` instead of a daemon, run
`M-x server-start` inside Emacs before connecting with `emacsclient`. Add
`(server-start)` to the Emacs configuration to enable that server automatically
on every normal GUI launch.

### System tools

Installs rsync, wget, Yazi, full FFmpeg and ImageMagick builds, Sevenzip, jq,
Poppler, resvg, Cryptomator, Hammerspoon, kitty, VeraCrypt, and Zotero.

The stage deliberately makes `ffmpeg-full` and `imagemagick-full` the linked
command-line variants. This may unlink Homebrew's standard `ffmpeg` and
`imagemagick` formulae, but does not uninstall them.

### Shell tools

Installs btop, colordiff, eza, fastfetch, fd, GNU findutils, fzf, gawk, GNU
getopt, GNU sed, GNU tar, Neovim, ripgrep, tmux, xz, and zoxide. It also clones:

- zsh-autosuggestions
- zsh-completions
- zsh-syntax-highlighting

### Network software

- Firefox for everyday browsing
- Mullvad Browser for privacy-focused, non-persistent browsing; it does not
  route traffic through the Tor network or include a VPN
- Nextcloud
- Tailscale's standalone macOS app
- nmap

### Development software

- checks for Apple's Command Line Tools and opens the installer when necessary
- installs Autoconf, Automake, clang-format, CMake, Flex, GDB, Gettext, Meson,
  Lua Language Server, Open MPI, ShellCheck, shfmt, and uv
- installs Oracle JDK by default
- installs the full MacTeX distribution, including `latexmk` and `pdflatex`
- installs the configured Clojure, Markdown-export, and Org Babel R
  dependencies: the official Clojure CLI, `clj-kondo`, MultiMarkdown, and R
- installs the `llm`, `ruff`, and latest `ty` Python tools with uv
- installs Rust through rustup, selects the stable toolchain, and adds
  `rust-analyzer`, Rust sources, Clippy, and rustfmt; Cargo is part of that
  toolchain

The existing Python 3 and clangd installations are retained. The Command Line
Tools provide the compiler used to build Tree-sitter grammars, and TexLab is
installed with Emacs. These tools are kept rather than replaced with parallel
installations.

Docker Desktop remains in the script as a commented-out optional cask because
its license agreement and privileged configuration require an interactive
first run.

If the Command Line Tools installer is opened, complete it and rerun the stage.

### Desktop productivity software

- Alfred
- ChatGPT
- Claude
- CleanShot X
- Hazel
- LibreOffice and its language pack
- Marked 3
- Obsidian
- Skim
- optionally links a personal TeX tree to `~/Library/texmf`

The `marked-app` cask installs Marked's direct-distribution build. Activate or
restore its direct/Paddle license inside the application.

The TeX link is created only when its source exists, and an existing target is
never overwritten.

### Graphics software

- gnuplot

## Manual installations

Some software is intentionally left outside the automated bootstrap:

- Install full Xcode from the Mac App Store only for Swift development. Emacs
  remains suitable for lightweight Swift editing without it.
- Sign in to the Mac App Store and install purchased applications.

## Safety and maintenance

- Scripts exit on errors, unset variables, and failed pipelines.
- The driver resolves script paths independently of the current directory.
- Running as root is rejected to prevent Homebrew and dotfiles from being
  installed into the root account.
- Repository clones and symlinks are checked before creation.
- macOS preference writes are explicit and safe to repeat.
- Remote downloads use HTTPS and fail on HTTP errors.
- Third-party Homebrew taps are explicitly trusted before their packages are
  loaded on Homebrew versions that support tap trust.
- Run `shellcheck bootstrap steps/basic-configuration steps/configure-macos
  steps/install-* steps/lib/common.sh` after editing scripts.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
