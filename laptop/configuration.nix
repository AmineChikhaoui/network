unstablePkgs:

{ config, lib, pkgs, ... }:
{
  imports =
    [
      ../common/users.nix
      ../common/hardening.nix
      ../common/prometheus.nix

      (import ../common/nix-config.nix unstablePkgs.nixUnstable)

      (import ../common/tailscale.nix unstablePkgs.tailscale)

      ./hardware-configuration.nix

      ./i3.nix
      ./fonts.nix

      # ./hydra.nix

      ./mbp.nix
      ./logicblox.nix

      ./nix-config.nix

      ./networking.nix
      ./backup.nix
      # flakes.hydra.nixosModules.hydra
    ];


  # added for OSX-KVM https://nixos.wiki/wiki/OSX-KVM
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1
    options v4l2loopback exclusive_caps=1 max_buffers=2
  '';

  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.supportedFilesystems = [ "exfat" "ntfs" ];
  boot.kernelModules = [ "kvm-amd" "kvm-intel" "v4l2loopback" ];
  boot.kernelParams = [ "fips=1" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.gnome.gnome-keyring.enable = true;

  # PulseAudio
  sound.enable = true;
  hardware.pulseaudio =
    {
      enable = true;
      package = pkgs.pulseaudioFull;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
    };

  # Yubikey setup
  services.udev.packages = [
    pkgs.libu2f-host
    pkgs.yubikey-personalization
  ];
  services.pcscd.enable = true;

  hardware.bluetooth.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "1password"
    ];
  };

  powerManagement.enable = true;

  environment.systemPackages =
    with pkgs; [
      # browsers
      unstablePkgs.firefox google-chrome chromium brave

      # shells & terminals
      zsh oh-my-zsh alacritty kitty unstablePkgs.fish

      # editors
      neovim emacs unstablePkgs.jetbrains.idea-community

      # networking
      wget bind telnet mtr networkmanagerapplet tcpdump
      wireshark

      # media
      pavucontrol ffmpeg

      # communication
      slack teams

      # photography
      unstablePkgs.darktable rapid-photo-downloader gphoto2
      geeqie

      # password managers & security
      _1password unstablePkgs._1password-gui gnupg pass passff-host keybase
      keybase-gui unstablePkgs.age sops
      unstablePkgs.agebox

      # VCS
      git mercurial

      # Languages/Compilers/Debuggers, ...

      # GCC toolchain
      gnumake gcc gdb rr lldb binutils

      ## Java
      openjdk

      ## Haskell
      ghc

      # NodeJS
      nodejs yarn yarn2nix

      ## Zig
      unstablePkgs.zig unstablePkgs.zls

      ## Python
      python
      (python3.withPackages(ps: [
        ps.python-lsp-server
        ps.pyls-isort ps.python-lsp-black
      ]))

      ## Rust
      rustup

      ## Golang
      unstablePkgs.go_1_18 unstablePkgs.delve

      ## ConfigLangs
      unstablePkgs.dhall unstablePkgs.dhall-json
      unstablePkgs.cue unstablePkgs.go-jsonnet

      # deployment tools
      unstablePkgs.nixopsUnstable unstablePkgs.terraform unstablePkgs.flyctl terraform-docs

      docker-compose

      # uncategorized
      shfmt
      apk-tools proot bubblewrap
      awscli ripgrep  patchelf  sqliteInteractive lsof hologram htop
      vlc slack bc jq yq smartmontools unstablePkgs.elfutils openssl cscope unetbootin pigz
      scrot perf-tools trace-cmd pinentry xclip xsel usbutils sysstat fd fzf
      criu i3status-rust direnv poetry google-cloud-sdk-gce nasm ncdu
      rofimoji
      unstablePkgs.fq
      niv
    ];

  services.lorri.enable = true;

  users.extraUsers.amine.shell = lib.mkForce "${unstablePkgs.fish}/bin/fish";

  programs.bash.promptInit = ''
    # Provide a nice prompt
    PROMPT_COLOR="1;31m"
    let $UID && PROMPT_COLOR="1;32m"
    PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\n\\$\[\033[0m\] "
    if test "$TERM" = "xterm"; then
    PS1="\[\033]2;\h:\u:\w\007\]$PS1"
    fi
    export EDITOR=vim
    export HISTFILESIZE=50000
    export HISTCONTROL=erasedups
    shopt -s histappend
    export PROMPT_COMMAND="history -a"
    export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S - '
    export PYTHONDONTWRITEBYTECODE=1
    alias vi=vim
  '';

  environment.enableDebugInfo = true;

  programs.vim.defaultEditor = true;

  programs.command-not-found.enable = true;

  # auto mount devices (sdcards, usb devices, ..)
  services.devmon.enable = true;

  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "0.6";
    };
    temperature = {
      day = 5500;
      night = 3700;
    };
  };

  location = {
    provider = "geoclue2";
  };

  # TODO switch to doas ??
  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      extraOptions = "--experimental --insecure-registry docker.chikhaoui.org:5000";
    };
    # virtualbox.host.enable = true;
  };

  services.autorandr.enable = true;
  services.upower.enable = true;
  services.netdata.enable = true;

  systemd.extraConfig = lib.mkForce ''
    DefaultLimitCORE=infinity
  '';

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_13;
  };

  # CRIU (https://www.criu.org) experiments
  # systemd.services.docker.path = [ pkgs.criu ];
  # programs.criu.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  my.users.extraGroups = [
    "networkmanager" "docker" "libvirtd" "vboxusers"
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ gutenprint gutenprintBin splix hplip];
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";
}
