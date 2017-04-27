require 'chefspec'

RSpec.describe 'cloudburrito::sshd' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.2.1511')
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'installs sshd' do
    expect(chef_run).to install_package 'openssh-server'
  end

  context 'sshd systemd unit' do
    it 'enabled' do
      expect(chef_run).to enable_systemd_unit 'sshd'
    end
    it 'started' do
      expect(chef_run).to start_systemd_unit 'sshd'
    end
  end

  context 'create /etc/ssh/sshd_config' do
    let(:fname) { '/etc/ssh/sshd_config' }
    it 'is file' do
      expect(chef_run).to create_file(fname)
    end
    it 'has mode 0644' do
      expect(chef_run).to create_file(fname).with(mode: 0644)
    end
    it 'owner is root' do
      expect(chef_run).to create_file(fname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_file(fname).with(group: 'root')
    end
    it 'notifies sshd systemd unit' do
      expect(chef_run.file(fname)).to notify('systemd_unit[sshd]').to(:restart).delayed
    end
  end
end
