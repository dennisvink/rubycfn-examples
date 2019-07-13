=begin

Creating a VPC
==============
For this example we are going to create a VPC using Rubycfn.
It creates the VPC, Internet Gateway, RouteTables, and the Subnet RouteTable Associations.
=end

# Method that returns an array of hashes with subnets.
# The 'offset' value must be unique per subnet so that subnets don't overlap. 
def vpc_subnets
  [
    {
      "es_private": {
        "owner": "example",
        "public": false,
        "offset": 1
      }
    },
    {
      "ec2_public": {
        "owner": "example",
        "public": true,
        "offset": 2
      }
    },
    {
      "ec2_private": {
        "owner": "example",
        "public": false,
        "offset": 3
      }
    },
    {
      "bastion_public": {
        "owner": "example",
        "public": true,
        "offset": 4
      }
    }
  ]
end

# Defaults to 10.0.0.0/16, but you ccan override the VPC CIDR with an ENV var.
variable :cidr_block,
	 default: "10.0.0.0/16",
	 value: ENV["VPC_CIDR_BLOCK"]

# Creates the VPC with DNS support and DNS hostnames
resource :example_vpc,
	 type: "AWS::EC2::VPC" do |r|
  r.property(:cidr_block) { cidr_block }
  r.property(:enable_dns_support) { true }
  r.property(:enable_dns_hostnames) { true }
end

# Create an Internet Gateway
resource :example_internet_gateway,
	 type: "AWS::EC2::InternetGateway"

# Create a route for the world (0.0.0.0/0)
resource :example_route,
	 type: "AWS::EC2::Route" do |r|
  r.property(:destination_cidr_block) { "0.0.0.0/0" }
  r.property(:gateway_id) { :example_internet_gateway.ref }
  r.property(:route_table_id) { :example_route_table.ref }
end

# Create the main route table
resource :example_route_table,
	 type: "AWS::EC2::RouteTable" do |r|
  r.property(:vpc_id) { :example_vpc.ref }
  r.property(:tags) do
    [
      {
	"Key": "Environment",
	"Value": "Example Route Table"
      }
    ]
  end
end

# Attach the VPC Gateway
resource :example_vpc_gateway_attachment,
	 type: "AWS::EC2::VPCGatewayAttachment" do |r|
  r.property(:internet_gateway_id) { :example_internet_gateway.ref }
  r.property(:vpc_id) { :example_vpc.ref }
end

# Iterate over our array of subnets, and create 3 subnets for each entry.
# Also associate the subnets with the route table.
vpc_subnets.each_with_index do |subnet, _subnet_count|
  subnet.each do |subnet_name, arguments|
    resource "example_#{subnet_name}_subnet".cfnize,
	     type: "AWS::EC2::Subnet",
	     amount: 3 do |r, index|
      r.property(:availability_zone) do
	{
	  "Fn::GetAZs": ""
	}.fnselect(index)
      end
      r.property(:cidr_block) do
	[
	  :example_vpc.ref("CidrBlock"),
	  (3 * arguments[:offset]).to_s,
	  (Math.log(256) / Math.log(2)).floor.to_s
	].fncidr.fnselect(index + (3 * arguments[:offset]) - 3)
      end
      r.property(:map_public_ip_on_launch) { arguments[:public] }
      r.property(:tags) do
	[
	  {
	    "Key": "owner",
	    "Value": arguments[:owner].to_s.cfnize
	  },
	  {
	    "Key": "resource_type",
	    "Value": subnet_name.to_s.cfnize
	  }
	]
      end
      r.property(:vpc_id) { "ExampleVpc".ref }
    end

    resource "example_#{subnet_name}_subnet_route_table_association".cfnize,
	     amount: 3,
	     type: "AWS::EC2::SubnetRouteTableAssociation" do |r, index|
      r.property(:route_table_id) { :example_route_table.ref }
      r.property(:subnet_id) { "example_#{subnet_name}_subnet#{index.zero? && "" || index + 1}".cfnize.ref }
    end

    # Generate outputs for these subnets
    3.times do |i|
      output "#{subnet_name}_subnet#{i.positive? ? (i + 1) : ""}_name".cfnize,
	     value: "example_#{subnet_name}_subnet#{i.positive? ? (i + 1) : ""}".cfnize.ref
    end
  end
end

# Finally, output the VPC Cidr and the VPC Id.
output :vpc_cidr,
       value: :example_vpc.ref("CidrBlock")
output :example_vpc_id,
       value: :example_vpc.ref
