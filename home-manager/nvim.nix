{config, lib, pkgs, ...}:

let
  lsp_via_npm = pkgs.writeShellScriptBin "lsp_via_npm" ''
    #!/bin/bash
    if [! -d ~/.npm-global/bin]; then
      mkdir ~/.npm-global
    fi
    npm config set prefix '~/.npm-global'
    export PATH=~/.npm-global/bin:$PATH
    npm i -g npm vscode-langservers-extracted bash-language-server
  '';
in
{
  programs = {
    neovim = {
      enable = true;
      withNodeJs = true;
      withPython3 = true;
      extraPackages = [];
      plugins = with pkgs.vimPlugins; [];
    };
  };
  home = {
    packages = with pkgs; [
      lsp_via_npm
      rnix-lsp
      sumneko-lua-language-server
      gopls
      pyright
      zk
      rust-analyzer
      clang-tools

      tree-sitter

      stylua
      black
      nixpkgs-fmt
      rustfmt
      beautysh
      nodePackages.prettier

      nodePackages.eslint

      lldb
    ];
  };
}
