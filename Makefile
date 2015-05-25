
.PHONY: all
all: install /usr/local/lib/python2.7/dist-packages/PyV8-1.0_dev-py2.7-linux-x86_64.egg /usr/bin/node /usr/bin/emcc /usr/bin/pypy


/usr/bin/node:
	wget -O /tmp/node-v0.10.36.tar.gz https://nodejs.org/dist/v0.10.36/node-v0.10.36.tar.gz
	cd /tmp ; tar -xzvf node-v0.10.36.tar.gz
	cd /tmp/node-v0.10.36 ; ./configure  --prefix=/usr
	cd /tmp/node-v0.10.36 ; make
	cd /tmp/node-v0.10.36 ; make install
	rm -rf /tmp/node-v0.10.36*


/usr/bin/pypy:
	mkdir -p /build
	# Ensure we have the repo checked out.
	if [ -d /build/pypy ]; then true; else git clone https://github.com/rfk/pypy /build/pypy; fi;
	# Ensure we're using up-to-date code.
	cd /build/pypy; git pull; git gc --aggressive
	# Build it, and link it into system path.
	python /build/pypy/rpython/bin/rpython --opt=jit --gcrootfinder=shadowstack --cc="gcc -m32" --thread /build/pypy/pypy/goal/targetpypystandalone.py --translationmodules
	cp /build/pypy-c /build/pypy/
	cp /build/libpypy-c.so /build/pypy/
	ln -s /build/pypy/pypy-c /usr/bin/pypy
	# Remove any build and vc files that we don't need at runtime.
	rm -rf /tmp/usession-* /tmp/ctypes_configure-*
	rm -rf /build/pypy/.git


/usr/bin/emcc: /usr/bin/node
	mkdir -p /build
	mkdir -p /build
	mkdir -p /var/cache/emscripten/cache
	chmod -R 777 /var/cache/emscripten
	# Fetch all the necessary repos.
	git clone https://github.com/kripken/emscripten /build/emscripten;
	git clone https://github.com/kripken/emscripten-fastcomp /build/emscripten-fastcomp
	git clone https://github.com/kripken/emscripten-fastcomp-clang /build/emscripten-fastcomp/tools/clang
	cd /build/emscripten ; git checkout -t origin/incoming
	cd /build/emscripten-fastcomp ; git checkout -t origin/incoming
	cd /build/emscripten-fastcomp/tools/clang ; git checkout -t origin/incoming
	# Hack around problem with missing netlink.h include.
	grep -v "AF_NETLINK" /build/emscripten/system/include/libc/sys/socket.h > /tmp/socket.h.new
	mv /tmp/socket.h.new /build/emscripten/system/include/libc/sys/socket.h
	# Build the emscripten-enabled clang toolchain.
	mkdir -p /tmp/emscripten
	cd /tmp/emscripten ; /build/emscripten-fastcomp/configure --enable-optimized --disable-assertions --enable-targets=host,js --prefix=/usr
	cd /tmp/emscripten ; make -j 4
	cd /tmp/emscripten ; make install
	# Symlink emcc into system path.
	ln -s /build/emscripten/emcc /usr/bin/emcc
	# Initialize emscripten config file
	echo "EMSCRIPTEN_ROOT = '/build/emscripten'" > /var/cache/emscripten/config
	echo "LLVM_ROOT = '/usr/bin'" >> /var/cache/emscripten/config
	echo "TEMP_DIR = '/tmp'" >> /var/cache/emscripten/config
	echo "NODE_JS = '/usr/bin/node'" >> /var/cache/emscripten/config
	echo "COMPILER_ENGINE = NODE_JS" >> /var/cache/emscripten/config
	echo "JS_ENGINES = [NODE_JS]" >> /var/cache/emscripten/config
	emcc --version > /dev/null
	emcc --clear-cache > /dev/null
	# Pre-compile common emscripten utilities
	cd /build/emscripten && python embuilder.py build libc
	cd /build/emscripten && python embuilder.py build native_optimizer
	cd /build/emscripten && python embuilder.py build struct_info
	# Remove any of the build and vc data that we no longer need.
	rm -rf /tmp/emscripten
	rm -rf /build/emscripten-fastcomp
	rm -rf /build/emscripten/.git


/usr/local/lib/python2.7/dist-packages/PyV8-1.0_dev-py2.7-linux-x86_64.egg:
	svn checkout https://pyv8.googlecode.com/svn/trunk/ /build/pyv8
	cd /build/pyv8; cat setup.py | sed "s/if os.uname/if False and os.uname/g" > setup.py.new; mv setup.py.new setup.py
	cd /build/pyv8; python setup.py build
	cd /build/pyv8; python setup.py install
	rm -rf /build/pyv8

