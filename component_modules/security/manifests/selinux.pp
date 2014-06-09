class security::selinux(
  $on = [],
  $off = []
)
{
  $any_on = inline_template("<%= !@on.empty? ? true : nil %>")
  $any_off = inline_template("<%= !@off.empty? ? true : nil %>")
  if $any_on and $any_off {
    fail('Inconsistent constraints on selinux')
  }
  if $any_on {
    exec { 'security::selinux /selinux/enforce 1':
      command => 'echo 1 > /selinux/enforce',
      unless  => 'grep 1 /selinux/enforce',
      path   => ['/bin']
    }
  } elsif $any_off {
    exec { 'security::selinux /selinux/enforce 0':
      command => 'echo 0 > /selinux/enforce',
      unless  => 'grep 0 /selinux/enforce',
      path   => ['/bin']
    }
  }
}

