# copy Script file to add nightly user
cookbook_file '/root/nightly_user_creation.sh' do
	source 'nightly_user_creation.sh'
	owner 'root'
	group 'root'
	mode '0744'
end


# copy  Script file to add nightly user
cookbook_file '/root/nigh_authorized_keys' do
	source 'nigh_authorized_keys'
	owner 'root'
	group 'root'
	mode '0644'
end

execute "run night user creation script" do
	command "/bin/bash /root/nightly_user_creation.sh"
end



