debian:
	bash make_debian_package.sh
clean:
	rm -rf target
.PHONY: debian
