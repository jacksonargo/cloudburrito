describe passwd.uids(0) do
  its('users') { should cmp 'root' }
  its('count') { should eq 1 }
end

describe shadow.uids(0) do
  its('users') { should cmp 'root' }
  its('count') { should eq 1 }
end

describe file('/etc/security/access.conf') do
  it { should be_file }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0644' }
  its('content') { should eq '+ : deploy : ALL\n+ : jackson : ALL\n+ : root : LOCAL\n - : ALL : ALL' }
end
