{
  lib,
  stdenv,
  stdenvNoCC,
  makeWrapper,
  python3,
  coreutils,
  findutils,
  gawk,
  gnugrep,
  gnused,
  curl,
  systemd,
  quickshell,
  stateDir ? null,
  cacheDir ? null,
  baseConfig ? null,
  sessionsDir ? null,
  compositor ? "",
  layouts ? "",
  extraEnv ? { },
}:

let
  binPath =
    lib.makeBinPath [
      coreutils
      findutils
      gawk
      gnugrep
      gnused
      curl
      systemd
      (lib.getBin stdenv.cc.libc)
    ]
    + ":/run/current-system/sw/bin";

  fixedEnv =
    lib.optionalAttrs (stateDir != null) { OOZELOGIN_DIR = stateDir; }
    // lib.optionalAttrs (cacheDir != null) { OOZELOGIN_CACHE = cacheDir; }
    // lib.optionalAttrs (baseConfig != null) { OOZELOGIN_BASE = "${baseConfig}"; }
    // lib.optionalAttrs (sessionsDir != null) { OOZELOGIN_SESSIONS = sessionsDir; }
    // lib.optionalAttrs (compositor != "") { OOZELOGIN_COMPOSITOR = compositor; }
    // lib.optionalAttrs (layouts != "") { OOZELOGIN_LAYOUTS = layouts; }
    // extraEnv;

  userDirFlags =
    lib.optional (stateDir == null) (
      "--run " + lib.escapeShellArg ''export OOZELOGIN_DIR="''${OOZELOGIN_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/oozelogin}"''
    )
    ++ lib.optional (cacheDir == null) (
      "--run " + lib.escapeShellArg ''export OOZELOGIN_CACHE="''${OOZELOGIN_CACHE:-''${XDG_CACHE_HOME:-$HOME/.cache}/oozelogin}"''
    );

  envFlags = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: value: "--set ${name} ${lib.escapeShellArg value}") fixedEnv
    ++ userDirFlags
  );
in
stdenvNoCC.mkDerivation {
  pname = "oozelogin";
  version = "0.1.0";
  src = lib.cleanSource ../.;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/oozelogin $out/bin
    cp -r qml/. $out/share/oozelogin/
    install -Dm755 tools/oozelogin-sync $out/bin/oozelogin-sync
    patchShebangs $out/bin

    makeWrapper ${quickshell}/bin/quickshell $out/bin/oozelogin-greeter \
      --add-flags "-p $out/share/oozelogin/shell.qml" \
      --prefix PATH : ${binPath} \
      ${envFlags}

    makeWrapper ${quickshell}/bin/quickshell $out/bin/oozelogin-settings \
      --add-flags "-p $out/share/oozelogin/settings.qml" \
      --prefix PATH : ${binPath} \
      --set OOZELOGIN_QS ${quickshell}/bin/quickshell \
      --set OOZELOGIN_SYNC $out/bin/oozelogin-sync \
      ${envFlags}

    makeWrapper ${quickshell}/bin/quickshell $out/bin/oozelogin-preview \
      --add-flags "-p $out/share/oozelogin/shell.qml" \
      --prefix PATH : ${binPath} \
      --set OOZELOGIN_PREVIEW 1 \
      ${envFlags}

    wrapProgram $out/bin/oozelogin-sync ${
      lib.concatStringsSep " " (
        lib.optional (stateDir != null) "--set OOZELOGIN_DIR ${lib.escapeShellArg stateDir}"
        ++ lib.optional (stateDir == null) (
          "--run " + lib.escapeShellArg ''export OOZELOGIN_DIR="''${OOZELOGIN_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/oozelogin}"''
        )
      )
    }
    runHook postInstall
  '';

  meta = {
    description = "Quickshell greeter for greetd with its own settings window";
    mainProgram = "oozelogin-settings";
    platforms = lib.platforms.linux;
  };
}
