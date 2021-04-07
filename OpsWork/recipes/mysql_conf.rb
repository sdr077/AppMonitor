#copy mysql.sh script to sevrver
cookbook_file '/root/mysql.sh' do
	source 'mysql.sh'
	owner 'root'
	group 'root'
	mode '0744'
end

execute "Install and configure mysql" do
	command "bash /root/mysql.sh"
end