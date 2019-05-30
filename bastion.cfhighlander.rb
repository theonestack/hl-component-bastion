CfhighlanderTemplate do

  DependsOn 'vpc'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'Ami', type: 'AWS::EC2::Image::Id'
    ComponentParam 'SpotPrice', ''
    ComponentParam 'InstanceType'
    ComponentParam 'KeyName'
    ComponentParam 'DnsDomain'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'AsgMin', 1
    ComponentParam 'AsgMax', 1
  end
end
