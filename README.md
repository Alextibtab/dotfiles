# Dotfiles

This repository contains all my dotfiles for customising my developer workflow.

## TODO:

Figure out how best to use GNU Stow with this workflow. Extract rice specific customisations to specific distro rice folder with instructions on how you'd either use the replacement config or paste code to certain file.

## Overview

This repository contains my personal dotfiles and configuration settings for various development tools and applications. These files help maintain a consistent development environment across different machines.

For generic distro agnostic tools the configurations are inside the `config` folder then any distro specific config live inside the `distros` folder as well as any rices I've used for that distro

---
## Installation

1. Clone this repository:
```bash
git clone https://github.com/Alextibtab/dotfiles.git
cd dotfiles
```
---
## Contents
The `config` folder contains configuration for generic tools.
- nvim
- nu
- starship
- alacritty
- tmux
- ohmyposh

The `distros` folder contains distro specific configurations for arch, nixos, void-linux etc...
also includes specific rices that I've used and the custom configuration done to achieve that.

---
## Usage

Each tool's configuration can be found in its respective directory. Review the contents before applying them to ensure they match your preferences.

---
## Customization

Feel free to fork this repository and modify the configurations to match your personal preferences and workflow.


