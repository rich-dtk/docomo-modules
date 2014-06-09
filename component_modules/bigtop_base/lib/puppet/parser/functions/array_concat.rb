# Concat arrays
Puppet::Parser::Functions::newfunction(:array_concat, :type => :rvalue) do |args|
  args.flatten(1)
end
