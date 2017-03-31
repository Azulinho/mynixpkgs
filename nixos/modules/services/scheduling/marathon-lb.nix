{ config, lib, pkgs, environment, virtualisation,  ... }:

with lib;

let

  cfg = config.services.marathon-lb;

in {

  ###### interface

  options.services.marathon-lb = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
	Whether to enable the marathon mesos LB.
      '';
    };

    port = mkOption {
      type = types.int;
      default = 9999;
      description = ''
	Marathon-LB listening port for HTTP connections.
      '';
    };

    extraCmdLineOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--groups=external" "--marathon http://localhost:8080" "--haproxy-map" ];
      description = ''
	Extra command line options to pass to Marathon-lb.
      '';
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.marathon-lb = {
      description = "marathon-lb Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "zookeeper.service" "mesos-master.service" "mesos-slave.service" "marathon.service" "docker.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker run -e PORTS=${ toString cfg.port } --net=host --privileged -v /dev/log:/dev/log mesosphere/marathon-lb:v1.4.3 ${ concatStringsSep " " cfg.extraCmdLineOptions } ";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
