require 'chefspec'

RSpec.describe 'cloudburrito::nginx' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.2.1511')
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'installs nginx' do
    expect(chef_run).to install_package 'nginx'
  end

  it 'enables the nginx service' do
    expect(chef_run).to enable_systemd_unit 'nginx'
  end

  it 'starts the nginx service' do
    expect(chef_run).to start_systemd_unit 'nginx'
  end
end
