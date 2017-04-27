# Install repo config
if node[:platform] =~ /redhat|centos/
  yum_repository 'nginx' do
    description 'Nginx repo'
    baseurl  "http://nginx.org/packages/#{node[:platform]}/7/$basearch/"
    gpgkey   'http://nginx.org/keys/nginx_signing.key'
    gpgcheck true
    enabled  true
  end
end

# Install the package
package 'nginx' do
  action :install
end

# Start nginx
systemd_unit 'nginx' do
  action [ :start, :enable ]
end
