
delayed_exec "Remove useless cron" do
  after_block_notifies :reload, resources(:service => "cron")
  block do
    updated = false
    crons = find_resources_by_name_pattern(/^\/etc\/cron.d\/.*$/).map{|r| r.name}
    Dir["/etc/cron.d/*"].each do |n|
      Kernel.system "dpkg -S #{n} > /dev/null 2>&1"
      is_system_file = $?.exitstatus == 0
      unless is_system_file || crons.include?(n)
        Chef::Log.info "Removing cron #{n}"
        File.unlink n
        updated = true
      end
    end
    updated
  end
end
