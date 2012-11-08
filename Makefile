MODULE = cobweb
VERSION = local
GEN = gen
DIST = ${GEN}/dist
TAR_IMAGE = ${GEN}/image/${MODULE}-${VERSION}
RUBY_VERSION=1.9.3
TAR = ${DIST}/${MODULE}-${VERSION}.tar.gz
RVM = ~/.rvm/bin/rvm
ARTIFACTS = app bootstrapping config cookbooks db doc lib public roles script thumbnails vendor

SRC = src/bin

DIRECTORIES = \
	${GEN} \
	${DIST} \
	${TAR_IMAGE} \
	${TAR_IMAGE}/lib

.PHONY: clean rvm

default: clean rvm test

${DIRECTORIES}:
	mkdir -p $@

clean:
	rm -rf ./${GEN}/rvm ./${GEN}/dist ./${GEN}/image

rvm:
	rvm install ${RUBY_VERSION}
	rvm --create use "${RUBY_VERSION}@cobweb"
	rvm-shell -c "gem install bundler"
	rvm-shell -c "bundle install"

test:
	rvm-shell -c "bundle exec rspec spec"
