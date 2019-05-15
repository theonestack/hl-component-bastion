CfhighlanderTemplate do
  DependsOn 'vpc@1.2.0'
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'Ami', type: 'AWS::EC2::Image::Id'
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
    end

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SecurityGroupDev'
    ComponentParam 'SecurityGroupOps'
    ComponentParam 'AsgMin'
    ComponentParam 'AsgMax'
  end
end
