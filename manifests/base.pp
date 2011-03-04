exec { "apt-get-update":
  command => "apt-get update",
  path => ["/bin", "/usr/bin"],
}

Package {
 ensure => installed,
 require => Exec["apt-get-update"]
}


class lighttpd
{
  package { "apache2.2-bin":
    ensure => absent,
  }

  package { "lighttpd":
    ensure => present,
  }

  service { "lighttpd":
    ensure => running,
    require => Package["lighttpd", "apache2.2-bin"],
  } 
}

class lighttpd-phpmysql-fastcgi inherits lighttpd
{

  package { "php5-cgi":
    ensure => present,
  }

  package { "mysql-server":
    ensure => present,
  }

  exec { "lighttpd-enable-mod fastcgi":
    path    => "/usr/bin:/usr/sbin:/bin",
    creates => "/etc/lighttpd/conf-enabled/10-fastcgi.conf",
    require =>  Package["php5-cgi"],
  }

}

class symfony-server inherits lighttpd-phpmysql-fastcgi
{

  package { "git-core":
    ensure => present,
  }

  package { ["php5-cli", "php5-sqlite"]:
    ensure => present,
    notify  => Service["lighttpd"],
  }

  exec { "git clone git://github.com/symfony/symfony1.git":
    path    => "/usr/bin:/usr/sbin:/bin",
    cwd => "/var/www",
    creates => "/var/www/symfony1",
    require => Package["git-core", "lighttpd"],
  }

}

class symfony-live-server inherits symfony-server
{

  file { "/etc/lighttpd/conf-available/99-hosts.conf":
    source => "/vagrant/files/conf/hosts.conf",
    notify  => Service["lighttpd"],
    require => Package["lighttpd"],
  }

  exec { "lighttpd-enable-mod hosts":
    path => "/usr/bin:/usr/sbin:/bin",
    creates => "/etc/lighttpd/conf-enabled/99-hosts.conf",
    require => File["/etc/lighttpd/conf-available/99-hosts.conf"],
    notify  => Service["lighttpd"],
  }

}

include symfony-live-server
notice("Symfony server is live!")
