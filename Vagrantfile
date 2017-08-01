# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

   config.vm.box = "ubuntu/trusty64"

   config.vm.provider "virtualbox" do |vb|
     vb.name = "grpc-perl"
     vb.memory = "4096"
   end

   config.vm.synced_folder "./", "/vagrant", type: "nfs"
   config.vm.boot_timeout = 300
   config.vm.network "private_network", ip: "192.168.33.15"

   config.vm.provider 'virtualbox' do |vb|
     vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
   end

   config.vm.provision "shell", inline: <<-SHELL
	apt-get -y update
	apt-get -y install build-essential autoconf libtool git
    apt-get -y install perl-doc

    ## install grpc
    cd /opt
    git clone -b $(curl -L http://grpc.io/release) https://github.com/grpc/grpc
    cd grpc
    git submodule update --init
    make
    make install

    ## install perl makefile.pl dependency
    export PERL_MM_USE_DEFAULT=1
    perl -MCPAN -e 'install Devel::CheckLib'

    ## add some handy aliases and enable debug info
	locale-gen UTF-8
	echo "alias gobase='cd /vagrant'" >> ~vagrant/.bash_profile
	echo "unset LC_CTYPE" >> ~vagrant/.bash_profile
	echo "cd /vagrant" >> ~vagrant/.bash_profile
	echo "export GRPC_TRACE=api" >> ~vagrant/.bash_profile
	echo "export GRPC_VERBOSITY=DEBUG" >> ~vagrant/.bash_profile
    echo 'alias git="echo not tonight, you know how it is..."' >> ~vagrant/.bash_profile
    echo "export PERL5LIB=/vagrant/blib/arch:/vagrant/blib/lib" >> ~vagrant/.bash_profile
    #echo "/vagrant/grpc/libs/opt" >> /etc/ld.so.conf.d/grpc-debug.conf
   SHELL
end
