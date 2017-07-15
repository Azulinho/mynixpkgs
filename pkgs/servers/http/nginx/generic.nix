{ stdenv, fetchurl, fetchFromGitHub, openssl, zlib, pcre, libxml2, libxslt, expat
, gd, geoip, fetchpatch
, withStream ? false
, modules ? []
, hardening ? true
, version, sha256, ...
}:

with stdenv.lib;

stdenv.mkDerivation {
  name = "nginx-${version}";

  src = fetchurl {
    url = "http://nginx.org/download/nginx-${version}.tar.gz";
    inherit sha256;
  };

  patches = [
    (fetchpatch {
      # CVE-2017-7529
      url = "http://hg.nginx.org/nginx/raw-rev/1adc6b0d5eaa";
      sha256 = "1iyxk2l2xg2wx2pzqsgyy3baik0b0g275j80hdxa3c6i06vcs4c3";
    })
  ];

  buildInputs =
    [ openssl zlib pcre libxml2 libxslt gd geoip ]
    ++ concatMap (mod: mod.inputs or []) modules;

  configureFlags = [
    "--with-http_ssl_module"
    "--with-http_v2_module"
    "--with-http_realip_module"
    "--with-http_addition_module"
    "--with-http_xslt_module"
    "--with-http_geoip_module"
    "--with-http_sub_module"
    "--with-http_dav_module"
    "--with-http_flv_module"
    "--with-http_mp4_module"
    "--with-http_gunzip_module"
    "--with-http_gzip_static_module"
    "--with-http_auth_request_module"
    "--with-http_random_index_module"
    "--with-http_secure_link_module"
    "--with-http_degradation_module"
    "--with-http_stub_status_module"
    "--with-ipv6"
    # Install destination problems
    # "--with-http_perl_module"
  ] ++ optional withStream "--with-stream"
    ++ optional (gd != null) "--with-http_image_filter_module"
    ++ optional (elem stdenv.system (with platforms; linux ++ freebsd)) "--with-file-aio"
    ++ map (mod: "--add-module=${mod.src}") modules;

  NIX_CFLAGS_COMPILE = [ "-I${libxml2.dev}/include/libxml2" ] ++ optional stdenv.isDarwin "-Wno-error=deprecated-declarations";

  preConfigure = (concatMapStringsSep "\n" (mod: mod.preConfigure or "") modules);

  hardeningEnable = [ "pie" ];

  postInstall = ''
    mv $out/sbin $out/bin
  '';

  meta = {
    description = "A reverse proxy and lightweight webserver";
    homepage    = http://nginx.org;
    license     = licenses.bsd2;
    platforms   = platforms.all;
    maintainers = with maintainers; [ thoughtpolice raskin fpletz ];
  };
}
