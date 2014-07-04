class impala::statestore_service()
{
  #TODO: just works for rhel/centos
  package { 'impala-state-store': } ->
  service { 'impala-state-store': 
    ensure => 'running'
  }
}