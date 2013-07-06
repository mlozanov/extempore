#!/bin/bash

rm TAGS
find -E . -regex '.*/.*\.(cpp|h)$' -print | etags -
find -E . -regex '.*/.*\.xtm$' -print | etags --append --regex='/(bind-[a-z]* \([a-z-_!]+\)/\1/' --language=scheme -
