require 'chefspec'

RSpec.describe 'cloudburrito::capistrano' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.2.1511')
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  context 'creates deploy user' do
    it 'is a user' do
      expect(chef_run).to create_user 'deploy'
    end

    it 'home is /home/deploy' do
      expect(chef_run).to create_user('deploy').with(home: '/home/deploy')
    end

    it 'shell is /bin/bash' do
      expect(chef_run).to create_user('deploy').with(shell: '/bin/bash')
    end
  end

  context 'creates ~deploy' do
    let(:dname) { '/home/deploy' }
    it 'is directory' do
      expect(chef_run).to create_directory(dname)
    end

    it 'has mode 0750' do
      expect(chef_run).to create_directory(dname).with(mode: 0750)
    end

    it 'owner is deploy' do
      expect(chef_run).to create_directory(dname).with(owner: 'deploy')
    end

    it 'group is deploy' do
      expect(chef_run).to create_directory(dname).with(group: 'deploy')
    end
  end

  context 'creates ~deploy/.ssh' do
    let(:dname) { '/home/deploy/.ssh' }
    it 'is directory' do
      expect(chef_run).to create_directory(dname)
    end

    it 'has mode 0700' do
      expect(chef_run).to create_directory(dname).with(mode: 0700)
    end

    it 'owner is deploy' do
      expect(chef_run).to create_directory(dname).with(owner: 'deploy')
    end

    it 'group is deploy' do
      expect(chef_run).to create_directory(dname).with(group: 'deploy')
    end
  end

  context 'creates ~deploy/.ssh/authorized_keys' do
    let(:fname) { '/home/deploy/.ssh/authorized_keys' }
    let(:content) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDq8aqinwZWEqG/qL/pZs74iN44FOf96Lk7UpgQzNOO3fYb+zAXUnLvlEpVPZUu2SGYLg+dldq576akKuXTqAVlfpcVzH6Z85z3UaIDN0fwPpe3O18WQ4RIcrZIXx6gOqlgsplE9w7eIK5uGnz2X4sFjA7BECEEfmGbcu5yoHqJdfZ0VSi5qO38CmsnPmCAQ7DV87lLXkK1N2wfrfQwb/6z1h8IiOl6HLhr+nQwJexFRhV0XVpJZ/PM3TCZT5Skrld+/QQj6Ekv5cyi0ADF9whhc7JglWcdk83ovLKvrVzeB1ZE+BGQo6d2Bm3RLnj47hnh/ldEAYP+diQD5nLCQdwvXYVwe8rsyOSEGfcVQkeenbTTWiPljx+RaRzfNnK2vHIkdGCSPatC9xk5/DN5TfuIM/ZsMMKmaibuGhD+9AYioeRaYY3AKXk0BKzll9gE+mnJx2bj6KNCcdwttTpAGvhtRl9OCI+kuoyQhTXbM4Mb0pvU77IFRUnKrh8SaRd3At4CGNZ4MpyjkXNfjVV6FZohLlEJphq46BdqMsSiKwfgaTcrpCe4bAVI9rHJ9WN01uIxZG1G8xXxwJNPnzKFDzzCvgW9Y+S5ft0VY/vhjVbBSaf6ZjzTp0TLsX+Ovh2TjywEIFv7fy0Odyi2ZguqhM6Rc51jvI9dj2EovMQ7p78Ew==' }
    it 'is file' do
      expect(chef_run).to create_file(fname)
    end

    it 'has mode 0600' do
      expect(chef_run).to create_file(fname).with(mode: 0600)
    end

    it 'has correct keys' do
      expect(chef_run).to create_file(fname).with(content: content)
    end

    it 'owner is deploy' do
      expect(chef_run).to create_file(fname).with(owner: 'deploy')
    end

    it 'group is deploy' do
      expect(chef_run).to create_file(fname).with(group: 'deploy')
    end
  end

  context 'creates deploy shared directories' do
    locations = [
      '/var/www/html/cloudburrito',
      '/var/www/html/cloudburrito/shared',
      '/var/www/html/cloudburrito/shared/config',
      '/var/www/html/cloudburrito/shared/log'
    ]
    locations.each do |location|
      context 'creates ' + location do
        let(:dname) { location }
        it 'is directory' do
          expect(chef_run).to create_directory(dname)
        end
        it 'has mode 0755' do
          expect(chef_run).to create_directory(dname).with(mode: 0755)
        end
        it 'owner is deploy' do
          expect(chef_run).to create_directory(dname).with(owner: 'deploy')
        end
        it 'group is deploy' do
          expect(chef_run).to create_directory(dname).with(group: 'deploy')
        end
      end
    end
  end

  context 'creates deploy shared files' do
    files = [
      '/var/www/html/cloudburrito/shared/config/secrets.yml',
      '/var/www/html/cloudburrito/shared/config/mongoid.yml'
    ]
    files.each do |file|
      context 'creates ' + file do
        let(:fname) { file }
        it 'is file' do
          expect(chef_run).to create_file(fname)
        end
        it 'has mode 0644' do
          expect(chef_run).to create_file(fname).with(mode: 0644)
        end
        it 'owner is deploy' do
          expect(chef_run).to create_file(fname).with(owner: 'deploy')
        end
        it 'group is deploy' do
          expect(chef_run).to create_file(fname).with(group: 'deploy')
        end
      end
    end
  end
end
