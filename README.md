# monome iii

A collection of monome iii scripts and some basic tooling for working on them.

https://monome.org/docs/iii/

https://github.com/monome/iii

## Setup

This project uses [mise](https://mise.jdx.dev) to create an isolated python3 environment for script development.

You don't need to do any of this to use these scripts.
But, if you don't already have diii installed, and don't want to use the web-based dii tool (https://monome.org/diii/), you can use this to get up and running.

1. Install mise: https://mise.jdx.dev/getting-started.html 
2. Install the mise tools for this project:
    ```
    mise install
    ````
3. Install diii:
    ```
    mise run install 
    ```

## Scripts

Various iii scripts.

## Types

I've written type definitions for current iii commands.
If you're using the Lua Language Server, this should prevent your IDE from flagging iii functions as undefined.
