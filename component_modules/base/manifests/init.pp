class base()
{
  if $::operatingsystem == 'Ubuntu' {
    exec {'base apt-get update':
      command => 'apt-get update',
      path    => ['/usr/bin']
    }
    package { 'emacs23-nox':}

  } elsif $::operatingsystem == 'Centos' {
    package { 'emacs-nox':}
  } else {
    fail("base not implemented yet for ${operatingsystem}")
  }

  package { ['elinks','lsof','mlocate']: }

}
