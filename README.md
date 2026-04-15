# nixpkgs-channel
My personal Modifications to the current nixpkgs channel

This is my first time removing my package changes out of my dots into their own dedicated repo/flake.

Since i tend to use pinned nixpkgs version (Currently 25.11) instead of pinning unstable occasionally i need to update a packages version quicker than the version pinning or security updates and this repo should now be where i store those package modifications along with any potential packages i use that arnt packaged on nixpkgs (oneday hopefully ill maintain/adopt them in nixpkgs too in this case).

Huge thanks to [drupol](https://github.com/drupol) for his guide into setting this repo up [drupol/my-own-nixpkgs](https://github.com/drupol/my-own-nixpkgs) and the flake parts tooling [drupol/pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts)