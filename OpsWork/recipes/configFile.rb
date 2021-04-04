

execute 'creating html folder' do
	command 'mkdir -p /var/www/html'
end

package 'httpd' do
	action :install
end

service 'httpd' do
  action [ :enable, :start ]
  supports :reload => true, :restart => true, :status => true, :stop => true
end

