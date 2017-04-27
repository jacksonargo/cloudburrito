require 'chefspec'

RSpec.describe 'cloudburrito::nginx' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.2.1511')
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  context 'creates nginx repo' do
    it 'is created' do
      expect(chef_run).to create_yum_repository('nginx')
    end
    it 'has correct description' do
      description = 'Nginx repo'
      expect(chef_run).to create_yum_repository('nginx').with(description: description)
    end
    it 'has correct baseurl' do
      baseurl = "http://nginx.org/packages/centos/7/$basearch/"
      expect(chef_run).to create_yum_repository('nginx').with(baseurl: baseurl)
    end
    it 'has correct gpgkey' do
      gpgkey = 'http://nginx.org/keys/nginx_signing.key'
      expect(chef_run).to create_yum_repository('nginx').with(gpgkey: gpgkey)
    end
    it 'is enabled' do
      expect(chef_run).to create_yum_repository('nginx').with(enabled: true)
    end
    it 'requires gpgcheck' do
      expect(chef_run).to create_yum_repository('nginx').with(gpgcheck: true)
    end
  end

  it 'installs nginx' do
    expect(chef_run).to install_package 'nginx'
  end

  context 'nginx systemd unit' do
    it 'is enabled' do
      expect(chef_run).to enable_systemd_unit 'nginx'
    end
    it 'is started' do
      expect(chef_run).to start_systemd_unit 'nginx'
    end
  end

  context 'creates /etc/nginx/ssl' do
    let(:dname) { '/etc/nginx/ssl' }
    it('is directory') { expect(chef_run).to create_directory dname }
    it 'has mode 0644' do
      expect(chef_run).to create_directory(dname).with(mode: 0755)
    end
    it 'owner is root' do
      expect(chef_run).to create_directory(dname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_directory(dname).with(group: 'root')
    end
  end

  context 'creates /etc/nginx/ssl/key.pem' do
    let(:fname) { '/etc/nginx/ssl/key.pem' }
    it('is file') { expect(chef_run).to create_file fname }
    it 'has mode 0600' do
      expect(chef_run).to create_file(fname).with(mode: 0600)
    end
    it 'owner is root' do
      expect(chef_run).to create_file(fname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_file(fname).with(group: 'root')
    end
    it 'notifies nginx systemd unit' do
      expect(chef_run.file(fname)).to notify('execute[make_nginx_priv]').to(:run).immediately
    end
  end

  context 'creates /etc/nginx/ssl/cert.pem' do
    let(:fname) { '/etc/nginx/ssl/cert.pem' }
    it('is file') { expect(chef_run).to create_file fname }
    it 'has mode 0644' do
      expect(chef_run).to create_file(fname).with(mode: 0644)
    end
    it 'owner is root' do
      expect(chef_run).to create_file(fname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_file(fname).with(group: 'root')
    end
    it 'notifies nginx systemd unit' do
      expect(chef_run.file(fname)).to notify('execute[make_nginx_cert]').to(:run).immediately
    end
  end

  context 'creates /etc/nginx/nginx.conf' do
    let(:fname) { '/etc/nginx/nginx.conf' }
    it('is cookbook_file') { expect(chef_run).to create_cookbook_file fname }
    it 'has mode 0644' do
      expect(chef_run).to create_cookbook_file(fname).with(mode: 0644)
    end
    it 'owner is root' do
      expect(chef_run).to create_cookbook_file(fname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_cookbook_file(fname).with(group: 'root')
    end
    it 'notifies nginx systemd unit' do
      expect(chef_run.cookbook_file(fname)).to notify('systemd_unit[nginx]').to(:restart).delayed
    end
  end
end
