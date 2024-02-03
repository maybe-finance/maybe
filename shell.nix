# Use `builtins.getFlake` if available
if builtins ? getFlake
then
  let
    scheme =
      if builtins.pathExists ./.git
      then "git+file"
      else "path";
  in
  (builtins.getFlake "${scheme}://${toString ./.}").devShells.${builtins.currentSystem}.default

# Otherwise we'll use the flake-compat shim
else
  (import
    (
      let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
      fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
    )
    { src = ./.; }
  ).shellNix
