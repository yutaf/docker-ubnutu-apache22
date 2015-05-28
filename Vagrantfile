# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'
Vagrant.configure("2") do |config|
  config.vm.define "my_docker" # proxy vagrant machine name
  config.vm.provider "docker" do |d|
    d.vagrant_vagrantfile = "./Vagrantfile.boot2docker"
    d.vagrant_machine = "docker_host"
    d.build_dir = "."
    d.build_args = "--tag='yutaf/ubuntu-apache22'"
#    d.image = "yutaf/apache22"
    d.name = "c1"
    # Add "--cap-add=SYS_ADMIN" to enable mounting
    d.create_args = ["--cap-add=SYS_ADMIN","-p","80:80"]
#    d.create_args = ["--cap-add=SYS_ADMIN","-p","8080:80"]
  end
  # disable default synced_folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # nfs
  config.vm.synced_folder "www/", "/srv/www", type: "nfs"
  # rsync
#  config.vm.synced_folder "www/", "/srv/www", type: "rsync", rsync__args: ["-rlpDvcK"]
end
