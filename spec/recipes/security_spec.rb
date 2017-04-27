require 'chefspec'

RSpec.describe 'cloudburrito::security' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.2.1511')
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  context 'creates /etc/security/access.conf' do
    let(:fname) { '/etc/security/access.conf' }
    it 'is a file' do
      expect(chef_run).to create_file(fname)
    end
    it 'owner is root' do
      expect(chef_run).to create_file(fname).with(owner: 'root')
    end
    it 'group is root' do
      expect(chef_run).to create_file(fname).with(group: 'root')
    end
    it 'mode is 0644' do
      expect(chef_run).to create_file(fname).with(mode: 0644)
    end
    it 'has correct contect' do
      content = '+ : deploy : ALL
+ : vagrant : ALL
+ : root : LOCAL
- : ALL : ALL'
      expect(chef_run).to create_file(fname).with(content: content)
    end
  end
end
