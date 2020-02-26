#! /bin/bash



mkdir old_python_debs && cd old_python_debs \
&& wget http://mirrors.kernel.org/ubuntu/pool/universe/p/python-defaults/python2_2.7.17-1_amd64.deb \
&& wget http://mirrors.kernel.org/ubuntu/pool/universe/p/python-defaults/python2-minimal_2.7.17-1_amd64.deb \
&& wget http://mirrors.kernel.org/ubuntu/pool/universe/p/python-defaults/libpython2-stdlib_2.7.17-1_amd64.deb \
&& sudo dpkg -i python2-minimal_2.7.17-1_amd64.deb \
&& sudo dpkg -i libpython2-stdlib_2.7.17-1_amd64.deb python2_2.7.17-1_amd64.deb \
&& sudo apt install atom
