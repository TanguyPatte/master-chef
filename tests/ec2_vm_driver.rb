
require 'fog'
require 'yaml'
require 'deep_merge'

class Ec2VmDriver < VmDriver

  @fog = nil

  def initialize
    config_file = get_env("EC2_CONFIG_FILE")
    @ami_type = get_env("AMI_TYPE").to_sym
    @config = YAML.load(File.read(File.join(File.dirname(__FILE__), 'ec2_base.yml')))
    @config.deep_merge! YAML.load(File.read(config_file))
  end

  def init
    params = @config[:params].merge(:image_id => @config[:amis][@ami_type])
    @node = fog.servers.create params
    @node.wait_for(120, 5) { ready? }
    puts "Server ready #{@node.id}, base ami #{@config[:amis][@ami_type]}"
    begin
      sleep(1)
      %x(nc -v -w 2 -z #{@node.public_ip_address} 22 2>&1 > /dev/null)
    end while $? != 0
    sleep 5
    puts "Server reachable #{@node.id}, ip #{@node.public_ip_address}."
  end

  def ip
    @node.public_ip_address
  end

  def destroy
    node_id = ENV["NODE_ID"] || @node.id
    unless ENV["KEEP_SERVER"]
      puts "Destroying server #{node_id}"
      fog.servers.find{|x| x.id == node_id}.destroy
    end
  end

  private

    def fog
      return @fog if @fog
      @fog = Fog::Compute.new @config[:fog]
    end
end

