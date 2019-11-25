import ./make-test-python.nix ({ lib, pkgs, ... }: {
  name = "riak";

  machine = {
    services.riak.enable = true;
    services.riak.package = pkgs.riak;
  };

  testScript = ''
    machine.start()

    machine.wait_for_unit("riak")
    machine.wait_until_succeeds("riak ping 2>&1")
  '';
})
