## User deploy

describe passwd.filter(user: 'deploy') do
  its('count') { should eq 1 }
  its('shells') { should cmp '/bin/bash' }
  its('homes')  { should cmp '/home/deploy' }
  its('passwords') { should eq ['x'] }
end

describe shadow.filter(user: 'deploy') do
  its('count') { should eq 1 }
  its('passwords') { should cmp '!' }
end

describe file('/home/deploy') do
  it { should be_directory }
  its('owner') { should eq 'deploy' }
  its('group') { should eq 'deploy' }
  its('mode') { should cmp '0750' }
end

describe file('/home/deploy/.ssh') do
  it { should be_directory }
  its('owner') { should eq 'deploy' }
  its('group') { should eq 'deploy' }
  its('mode') { should cmp '0700' }
end

describe file('/home/deploy/.ssh/authorized_keys') do
  it { should be_file }
  its('owner') { should eq 'deploy' }
  its('group') { should eq 'deploy' }
  its('mode') { should cmp '0600' }
  its('content') do
    should eq "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDq8aqinwZW\
EqG/qL/pZs74iN44FOf96Lk7UpgQzNOO3fYb+zAXUnLvlEpVPZUu2SGYLg+dldq576akKuXTqAVlfpc\
VzH6Z85z3UaIDN0fwPpe3O18WQ4RIcrZIXx6gOqlgsplE9w7eIK5uGnz2X4sFjA7BECEEfmGbcu5yoH\
qJdfZ0VSi5qO38CmsnPmCAQ7DV87lLXkK1N2wfrfQwb/6z1h8IiOl6HLhr+nQwJexFRhV0XVpJZ/PM3\
TCZT5Skrld+/QQj6Ekv5cyi0ADF9whhc7JglWcdk83ovLKvrVzeB1ZE+BGQo6d2Bm3RLnj47hnh/ldE\
AYP+diQD5nLCQdwvXYVwe8rsyOSEGfcVQkeenbTTWiPljx+RaRzfNnK2vHIkdGCSPatC9xk5/DN5Tfu\
IM/ZsMMKmaibuGhD+9AYioeRaYY3AKXk0BKzll9gE+mnJx2bj6KNCcdwttTpAGvhtRl9OCI+kuoyQhT\
XbM4Mb0pvU77IFRUnKrh8SaRd3At4CGNZ4MpyjkXNfjVV6FZohLlEJphq46BdqMsSiKwfgaTcrpCe4b\
AVI9rHJ9WN01uIxZG1G8xXxwJNPnzKFDzzCvgW9Y+S5ft0VY/vhjVbBSaf6ZjzTp0TLsX+Ovh2TjywE\
IFv7fy0Odyi2ZguqhM6Rc51jvI9dj2EovMQ7p78Ew=="
  end
end

## Deploy files

%w[
  /var/www/html/cloudburrito.us
  /var/www/html/cloudburrito.us/shared
  /var/www/html/cloudburrito.us/shared/log
  /var/www/html/cloudburrito.us/shared/config
].each do |dir|
  describe file(dir) do
    it { should be_directory }
    its('owner') { should eq 'deploy' }
    its('group') { should eq 'deploy' }
    its('mode')  { should cmp '0755' }
  end
end

%w[
  /var/www/html/cloudburrito.us/shared/config/mongoid.yml
  /var/www/html/cloudburrito.us/shared/config/secrets.yml
].each do |file|
  describe file(file) do
    it { should be_directory }
    its('owner') { should eq 'deploy' }
    its('group') { should eq 'deploy' }
    its('mode')  { should cmp '0600' }
  end
end
