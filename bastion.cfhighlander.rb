CfhighlanderTemplate do
  DependsOn 'vpc@1.1.0'
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'BastionAmi', isGlobal: true
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
    subnet_parameters({'public'=>{'name'=>'Public'}}, maximum_availability_zones)
    OutputParam component: 'vpc', name: 'VPCId'
    OutputParam component: 'vpc', name: 'SecurityGroupDev'
    OutputParam component: 'vpc', name: 'SecurityGroupOps'
  end
end
