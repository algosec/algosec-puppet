$test_app_name = 'puppet-test-application'

abf_application{$test_app_name:;} -> abf_flow {
  'flow with no optional fields defined':
    application  => $test_app_name,
    sources      => ['192.168.1.1'],
    destinations => ['192.168.2.2'],
    services     => ['HTTP', 'tcp/456'];
  # 'flow with optional fields defined':
  #   application  => $test_app_name,
  #   sources      => ['192.168.1.1', '10.0.0.1/16'],
  #   destinations => ['192.168.2.2', '10.0.0.2/16'],
  #   services     => ['HTTP', 'tcp/456'],
  #   users        => ['some-user'],
  #   applications => ['app1', 'app2'],
  #   comment      => 'some comment';
  "${test_app_name}/flow with the application defined in the title":
    sources      => ['192.168.1.1'],
    destinations => ['192.168.2.2'],
    services     => ['HTTP', 'tcp/456'];
}
