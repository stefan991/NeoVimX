NeoVimX
=======

This is a proof of concept Neovim OS X Client.

The the hardcoded neovim address is: /tmp/neovim. Run Neovim with this command:

```
NEOVIM_LISTEN_ADDRESS=/tmp/neovim nvim
```

It is based on the redraw events in this PR: https://github.com/neovim/neovim/pull/781

To handle the end of window (~ after the last line), I implemented 'redraw:win_end', see https://gist.github.com/stefan991/92a5f9c8f3670f03b0f2

