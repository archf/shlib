TARGET = shlib_template_standalone.sh
SHELL = bash

.ONESHELL:
.PHONY: build
build:
	cat shlib <(tail --lines=+3 shlib_template.sh) \
		| sed "s/shlib_template/shlib_template_standalone/" > ${TARGET}
	chmod +x ${TARGET}
