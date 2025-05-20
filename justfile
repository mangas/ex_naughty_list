help:
    @just -l

deps:
    mix deps.get

build:
    mix escript.build

release:
    mix release --overwrite

run *ARGS: build
    ./naughty_list run {{ ARGS }}

run-example: build
    ./naughty_list QmdKXcBUHR3UyURqVRQHu1oV6VUkBrhi2vNvMx3bNDnUCc QmY67iZDTsTdpWXSCotpVPYankwnyHXNT7N95YEn8ccUsn

run-list-sgs: build
    ./naughty_list list-subgraphs
