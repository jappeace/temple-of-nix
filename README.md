[![Jappiejappie](https://img.shields.io/badge/twitch.tv-jappiejappie-purple?logo=twitch)](https://www.twitch.tv/jappiejappie)

> run, run before it\'s too late.

This is a twitch chatbot that is written in the nix programming langauge.
It uses bash if we couldn't figure out how to do something in nix.
The purpose should be to rely on nix, as much as possible.

# Usage
Make sure you're a trusted user in your nix configuration (the script breaks sandbox, you have been warned):
```nix
nix.trustedUsers = ["YOURUSERNAME" "root"];
```

```shell
make run
```


## Register on twitch api

https://dev.twitch.tv/docs/authentication

# Docs

Use helix api:
https://dev.twitch.tv/docs/

Nix json:
https://nixos.org/nix/manual/#builtin-fromJSON


## ii
use file system for arbitrary irc:
https://tools.suckless.org/ii/


## Weechat
run arbitrary commands:

weechat -r "/help;/guile eval (list (sleep 5) (display \"hello lumie\"));/quit"
