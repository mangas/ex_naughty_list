help:
    @just -l

deps:
    mix deps.get

build:
    mix escript.build

release:
    mix release --overwrite

run-example: build
    ./naughty_list QmdKXcBUHR3UyURqVRQHu1oV6VUkBrhi2vNvMx3bNDnUCc QmY67iZDTsTdpWXSCotpVPYankwnyHXNT7N95YEn8ccUsn

run-list-sgs:
    ./naughty_list list-subgraphs
