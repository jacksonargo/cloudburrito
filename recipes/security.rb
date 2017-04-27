# Create access.conf
file '/etc/security/access.conf' do
  owner 'root'
  group 'root'
  mode 0644
  content '+ : deploy : ALL
+ root : LOCAL
- ALL : ALL'
end

