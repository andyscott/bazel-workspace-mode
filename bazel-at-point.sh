#!/usr/bin/env bash

set -eou pipefail

mode="$1"
root="$2"
path="$3"
pos="$3"

eval cd "$root"

label="$(bazel query $path 2>/dev/null)"

case "$mode" in
    "build")
	expr="\$q - tests(\$q)"
	;;
    "format")
	exit 1
	;;
    "test")
	expr="tests(\$q)"
	;;
    *)
	exit 1
	;;
esac

target="$(bazel query "let q = same_pkg_direct_rdeps($label) in $expr" 2>/dev/null | head)"

printf "$target"
