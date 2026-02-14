# monome-iii

A collection of [monome iii](https://github.com/monome/iii) scripts and some basic tooling for working on them.

## Setup

This project uses [asdf](https://asdf-vm.com) with the direnv and python plugins to create an isolated python3 environment for script development.

You don't need to do any of this to use these scripts.
But, if you don't already have diii installed, you can use this to get up and running.

1. Install asdf: https://asdf-vm.com/guide/getting-started.html
2. Install the asdf packages for this project:
    ```
    asdf install
    ````
3. Install diii:
    ```
    pip install -r requirements.txt
    ```

## Scripts

Various iii scripts.

## Types

I've written type definitions for current iii commands.
If you're using the Lua Language Server, this should prevent your IDE from flagging iii functions as undefined.

## Resources

- https://monome.org/docs/iii/
- https://github.com/monome/iii