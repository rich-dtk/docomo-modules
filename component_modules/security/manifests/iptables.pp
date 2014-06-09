class security::iptables(
  $on = [],
  $off = [],
  $deny_ports = [],
  $allow_ports = []
)
{
  $any_deny_ports = inline_template("<%= !@deny_ports.empty? ? true : nil %>")
  $any_allow_ports = inline_template("<%= !@allow_ports.empty? ? true : nil %>")

  if $any_deny_ports or $any_allow_ports {
    $any_on = true
    $any_off = false
  } else {
    $any_on = inline_template("<%= !@on.empty? ? true : nil %>")
    $any_off = inline_template("<%= !@off.empty? ? true : nil %>")
  }

  if $any_on and $any_off {
    fail('Inconsistent constraints on iptables')
  }
  if $any_on {
    if $any_allow_ports {
      security::iptables::rule { $allow_ports:
        type    => 'allow'
      }
    }

    if $any_deny_ports {
      security::iptables::rule { $deny_ports:
        type    => 'deny'
      }
    }
    if !$any_allow_ports and !$any_deny_ports {
       service { 'iptables': 
         ensure => true
       }
    }
  } elsif $any_off {
    service { 'iptables': 
      ensure => false
    }
  }
}

define security::iptables::rule(
  $type
)
{
  include security::iptables::rule::common
  #TODO: check that is right syntax
  $protocol = inline_template('<%= @name.split("/")[0] %>')
  $port = inline_template('<%= @name.split("/")[1] %>')
  notice("type=${type};port=${port};protocol={$protocol}")
  if $type == 'allow' {
    iptables::allow { $name:
      port     => $port,
      protocol => $protocol
    }
   } elsif $type == 'deny'  {
     iptables::drop { $name:
       port     => $port,
       protocol => $protocol
     }
   } else {    
     fail("Illegal rule type ${type}")
   }
}

class security::iptables::rule::common()
{
  user { 'puppet':
    gid => 'puppet'
  }
}
