class ganglia::python_modules(
  $modules = ['diskstat']
) inherits ganglia::params
{

  if $python_package_name ==  undef {
    fail("ganglia::python_modules is not supported on this OS")
  }

  package { 'python':
    ensure => 'present'
  } 
  package { $python_package_name:
    ensure  => 'present',
    require => Package['python'] 
  }

  class { 'ganglia::python_modules::configure':
    modules => $modules,
    require => Package[$python_package_name],
    notify  => Service[$gmond_service_name]
  }
}

class ganglia::python_modules::configure(
  $modules
)
{
  ganglia::python_module { $modules: }
}

#name is python module name
define ganglia::python_module()
{

  $source_base = "puppet:///modules/ganglia/gmond_python_modules/${name}"

  file { "${ganglia::params::configd_dir}/${name}.pyconf":
    source => "${source_base}/conf.d/${name}.pyconf"
  }

  file { "${ganglia::params::python_mod_exec_dir}/${name}.py":
    source => "${source_base}/python_modules/${name}.py"
  }
}