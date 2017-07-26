# Class: cmantix/nginxphp::php
#
# This module is made to install Nginx and php-fpm together.
#
# Parameters:
#   $php_packages list of extra php packages
#   $withppa set to true if you are using php 5.4 from ppa
#
# Actions:
#    install php-fpm as well as base packages
#
# Requires:
#    nginxphp
#
# Sample Usage:
#     include nginxphp::nginxphp
#
class nginxphp7::php (
  $php_packages,
){
  # install FPM
  package {
    'php7.0-fpm' :
      ensure => latest,
  }

  service {
    'php7.0-fpm':
      ensure => running,
      provider => systemd,
      enable => true,
      hasrestart => true,
      hasstatus   => true,
      require => Package['php7.0-fpm'],
      restart => "/etc/init.d/php7.0-fpm restart"
  }

  # remove fpm default pool
  file {
    'fpm-disable-default' :
      path => '/etc/php7.0/fpm/pool.d/www.conf',
      ensure => absent,
      notify => Service['php7.0-fpm'],
      require => Package['php7.0-fpm']
  }

  # install base PHP
  $basePHP = [
    'php7.0-cli',
    "php7.0-common",
    "php7.0-dev"
  ]
  package {
    $basePHP:
      ensure => latest,
  }

  # install all required packages
  package {
    $php_packages:
      ensure => latest,
      notify => Service["php7.0-fpm"],
  }
}

# Function: cmantix/nginxphp::fpmconfig
#
# Set FPM pool configuration
#
# Parameters:
#   $php_devmode [default:false]  Enable debug logging and .
#   $fpm_user    [default:www-data] User that runs the pool.
#   $fpm_group   [default:www-data] Group that runs the pool.
#   $fpm_listen  [default:127.0.0.1:9002] IP and port that the pool runs on.
#   $fpm_allowed_clients [default:127.0.0.1] Client ips that can connect to the pool.
#
# Actions:
#    install php-fpm pool configuration
#
# Requires:
#    nginxphp::php
#
# Sample Usage:
#     nginxphp::fpmconfig { 'bob':
#       php_devmode   => true,
#       fpm_user      => 'vagrant',
#       fpm_group     => 'vagrant',
#       fpm_allowed_clients => ''
#     }
#
define nginxphp7::fpmconfig (
  $php_devmode              = false,
  $fpm_user                 = 'www-data',
  $fpm_group                = 'www-data',
  $fpm_listen               = '127.0.0.1:9002',
  $fpm_allowed_clients      = '127.0.0.1',
  $fpm_max_children         = '10',
  $fpm_start_servers        = '4',
  $fpm_min_spare_servers    = '2',
  $fpm_max_spare_servers    = '6',
  $fpm_catch_workers_output = false,
  $fpm_error_log            = false,
  $fpm_access_log           = false,
  $fpm_slow_log             = false,
  $fpm_log_level            = undef,
  $fpm_rlimit_files         = undef,
  $fpm_rlimit_core          = undef,
  $pool_cfg_append          = undef,
  $chroot                   = false,
  $include                  = '/etc/php/7.0/fpm/pool.d/*.conf',
  $pid                      = '/run/php/php7.0-fpm.pid',
  $error_log                = '/var/log/php7.0-fpm.log',
){
  # set config file for the pool
  file {"fpm-pool-${name}":
    path            => "/etc/php/7.0/fpm/pool.d/${name}.conf",
    owner           => 'root',
    group           => 'root',
    mode            => '0644',
    notify          => Service['php7.0-fpm'],
    require         => Package['php7.0-fpm'],
    content         => template('nginxphp7/pool.conf.erb'),
  }

  # set config file for the pool
  if ! defined(File["/etc/php/7.0/fpm/php-fpm.conf"]) {
    file {'/etc/php/7.0/fpm/php-fpm.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Service['php7.0-fpm'],
      require => Package['php7.0-fpm'],
      content => template('nginxphp7/php-fpm.conf.erb')
    }
  }
}
