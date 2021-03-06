require 'mixlib/shellout'
require 'optparse'

add_command 'test', 'Run the Supermarket installation test suite', 2 do
  options = {}
  OptionParser.new do |opts|
    opts.on '-J', '--junit-xml PATH' do |junit_xml|
      options[:junit_xml] = junit_xml
    end
  end.parse!

  command_text = "/opt/supermarket/embedded/bin/rspec" \
    " -I /opt/supermarket/embedded/cookbooks/omnibus-supermarket/test/integration/default/serverspec" \
    " --format documentation" \
    " --color"

  if options[:junit_xml]
    command_text += " --require yarjuf" \
      " --format JUnit" \
      " --out #{options[:junit_xml]}"
  end

  command_text += ' /opt/supermarket/embedded/cookbooks/omnibus-supermarket/test/integration/default/serverspec/**/*_spec.rb' \

  shell_out = Mixlib::ShellOut.new(command_text)
  shell_out.run_command
  $stdout.puts shell_out.stdout
  $stderr.puts shell_out.stderr
  exit shell_out.exitstatus
end
