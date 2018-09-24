CfhighlanderTemplate do
  DependsOn stdext
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'Ami', type: 'AWS::EC2::Image::Id'
    ComponentParam 'HostedZoneId'

    MappingParam('InstanceType') do
      map 'EnvironmentType'
      attribute 'BastionInstanceType'
    end
    MappingParam('KeyName') do
      map 'AccountId'
      attribute 'KeyName'
    end
    MappingParam('DnsDomain') do
      map 'AccountId'
      attribute 'DnsDomain'
    end

    maximum_availability_zones.times do |az|
      ComponentParam "SubnetPublic#{az}"
      MappingParam "Az#{az}" do
          map 'AzMappings'
          attribute "Az#{az}"
      end
    end

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SecurityGroupDev', type: 'AWS::EC2::SecurityGroup::Id'
    ComponentParam 'SecurityGroupOps', type: 'AWS::EC2::SecurityGroup::Id'
  end
end
