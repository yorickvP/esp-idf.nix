{ stdenv, fetchgit, fetchurl, python2, python3, autoPatchelfHook, libusb1, zlib, git, perl
, lib, mkPython }:
let
  platforms = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-arm64";
    "armv7l-unknown-linux" = "linux-armel";
    "armv7-unknown-linux" = "linux-armhf";
    "i686-linux" = "linux-i686";
    "x86_64-darwin" = "macos";
    "aarch64-darwin" = "macos-arm64";
    "i686-windows" = "win32";
    "x86_64-windows" = "win64";
  };
  platform = platforms.${stdenv.system};
  prefetch = builtins.fromJSON (builtins.readFile ./esp-idf-prefetch.json);
  src = fetchgit {
    inherit (prefetch) url rev sha256;
    fetchSubmodules = true;
    #"please run `nix-prefetch-git https://github.com/${owner}/${repo} ${rev} --fetch-submodules > nix/esp-idf-prefetch.json`";
  };
  tools =
    (builtins.fromJSON (builtins.readFile "${src}/tools/tools.json")).tools;
  toDownload = tool:
    let
      version = lib.findFirst ({ status, ... }: status == "recommended") null
        tool.versions;
      download = version."${platform}" or null;
    in if download != null then
      fetchurl { inherit (download) url sha256; }
    else
      null;
  toolsTars = (builtins.filter (x: x != null) (builtins.map toDownload tools));
  pythonIdf =
    let origRequirements = builtins.readFile "${src}/requirements.txt";
        requirements = builtins.replaceStrings
          [ "file://"  "--only-binary"  ]
          [ "#file://" "#--only-binary" ]
          origRequirements;
    in mkPython {
      requirements = requirements;
      ignoreDataOutdated = true; # hack
      python = "python39";
    };
in stdenv.mkDerivation {
  pname = "esp-idf";
  version = "4.4.1";
  inherit src;
  buildInputs = [ pythonIdf stdenv.cc.cc.lib python2 libusb1 zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  passthru.python = pythonIdf;
  propagatedBuildInputs = [ pythonIdf git perl ];
  buildPhase = ''
    sed \
      -e '/^gdbgui/d' \
      -e '/^kconfiglib/c kconfiglib' \
      -e '/^construct/c construct' \
      -i requirements.txt
    echo v$version > version.txt
    export IDF_TOOLS_PATH=$out/tool
    mkdir -p $out/tool/dist
    ${ # symlink all tools
      lib.concatMapStringsSep "\n" (tool: ''
        ln -s ${tool} $out/tool/dist/$(echo ${tool} | cut -d'-' -f 2-)
      '') toolsTars
    } 
    patchShebangs .
    python3 ./tools/idf_tools.py install
    # remove .tar.gz dependencies
    rm -rf $out/tool/dist
  '';
  installPhase = ''
    cp -r ./. $out/
    mkdir $out/bin
    ln -s $out/tool/tools/*/*/*/bin/* $out/bin/
  '';
}

