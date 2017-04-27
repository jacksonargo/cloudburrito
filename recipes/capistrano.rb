# Create our deploy user

user 'deploy' do
  action :create
  home   '/home/deploy'
  shell  '/bin/bash'
end

# Create deploy home

directory '/home/deploy' do
  action :create
  owner  'deploy'
  group  'deploy'
  mode   0750
end

# Create the deploy .ssh dir

directory '/home/deploy/.ssh' do
  action :create
  owner  'deploy'
  group  'deploy'
  mode   0700
end

# Add the authorized keys

file '/home/deploy/.ssh/authorized_keys' do
  action :create
  owner  'deploy'
  group  'deploy'
  mode   0600
  content 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDq8aqinwZWEqG/qL/pZs74iN44FOf96Lk7UpgQzNOO3fYb+zAXUnLvlEpVPZUu2SGYLg+dldq576akKuXTqAVlfpcVzH6Z85z3UaIDN0fwPpe3O18WQ4RIcrZIXx6gOqlgsplE9w7eIK5uGnz2X4sFjA7BECEEfmGbcu5yoHqJdfZ0VSi5qO38CmsnPmCAQ7DV87lLXkK1N2wfrfQwb/6z1h8IiOl6HLhr+nQwJexFRhV0XVpJZ/PM3TCZT5Skrld+/QQj6Ekv5cyi0ADF9whhc7JglWcdk83ovLKvrVzeB1ZE+BGQo6d2Bm3RLnj47hnh/ldEAYP+diQD5nLCQdwvXYVwe8rsyOSEGfcVQkeenbTTWiPljx+RaRzfNnK2vHIkdGCSPatC9xk5/DN5TfuIM/ZsMMKmaibuGhD+9AYioeRaYY3AKXk0BKzll9gE+mnJx2bj6KNCcdwttTpAGvhtRl9OCI+kuoyQhTXbM4Mb0pvU77IFRUnKrh8SaRd3At4CGNZ4MpyjkXNfjVV6FZohLlEJphq46BdqMsSiKwfgaTcrpCe4bAVI9rHJ9WN01uIxZG1G8xXxwJNPnzKFDzzCvgW9Y+S5ft0VY/vhjVbBSaf6ZjzTp0TLsX+Ovh2TjywEIFv7fy0Odyi2ZguqhM6Rc51jvI9dj2EovMQ7p78Ew=='
end

# Create our shared directories

shared_directories = [
  '/var/www/html/cloudburrito',
  '/var/www/html/cloudburrito/shared',
  '/var/www/html/cloudburrito/shared/log',
  '/var/www/html/cloudburrito/shared/config'
]
shared_directories.each do |shared_directory|
  directory shared_directory do
    action :create
    owner 'deploy'
    group 'deploy'
    mode 0755
  end
end

# Create our shared files

shared_files = [
  '/var/www/html/cloudburrito/shared/config/secrets.yml',
  '/var/www/html/cloudburrito/shared/config/mongoid.yml'
]

shared_files.each do |shared_file|
  file shared_file do
    action :create
    owner 'deploy'
    group 'deploy'
    mode 0644
  end
end
