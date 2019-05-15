CloudFormation do

  az_conditions_resources('SubnetPublic', maximum_availability_zones)

  Condition('HostedZoneNameProvided', FnNot(FnEquals(Ref('HostedZoneName'), '')))
  Condition('RecordNameProvided', FnNot(FnEquals(Ref('RecordName'), '')))

  EC2_SecurityGroup('SecurityGroupBastion') do
    GroupDescription FnJoin(' ', [ Ref('EnvironmentName'), component_name ])
    VpcId Ref('VPCId')
    SecurityGroupIngress sg_create_rules(securityGroups, ip_blocks) if defined? securityGroups
  end

  EIP('BastionIPAddress') do
    Domain 'vpc'
  end

  RecordSet('BastionDNS') do
    HostedZoneName FnIf('HostedZoneNameProvided', FnSub('.${DnsDomain}.'), Ref('HostedZoneName'))
    Comment 'Bastion Public Record Set'
    Name FnIf('RecordNameProvided', FnSub('bastion.${EnvironmentName}.${DnsDomain}.'), Ref('RecordName'))
    Type 'A'
    TTL 60
    ResourceRecords [ Ref("BastionIPAddress") ]
  end

  Role('Role') do
    AssumeRolePolicyDocument service_role_assume_policy('ec2')
    Path '/'
    Policies(IAMPolicies.new.create_policies([
      'associate-address',
      'ec2-describe',
      'cloudwatch-logs',
      'ssm'
    ]))
  end

  InstanceProfile('InstanceProfile') do
    Path '/'
    Roles [Ref('Role')]
  end

  LaunchConfiguration('LaunchConfig') do
    ImageId Ref('Ami')
    InstanceType Ref('InstanceType')
    AssociatePublicIpAddress true
    IamInstanceProfile Ref('InstanceProfile')
    KeyName Ref('KeyName')
    SecurityGroups [ Ref('SecurityGroupBastion') ]
    UserData FnBase64(FnJoin("",[
      "#!/bin/bash\n",
      "aws --region ", Ref("AWS::Region"), " ec2 associate-address --allocation-id ", FnGetAtt('BastionIPAddress','AllocationId') ," --instance-id $(curl http://169.254.169.254/2014-11-05/meta-data/instance-id -s)\n",
      "hostname ", Ref('EnvironmentName') ,"-" ,"bastion-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\n",
      "sed '/HOSTNAME/d' /etc/sysconfig/network > /tmp/network && mv -f /tmp/network /etc/sysconfig/network && echo \"HOSTNAME=", Ref('EnvironmentName') ,"-" ,"bastion-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\" >>/etc/sysconfig/network && /etc/init.d/network restart\n",
    ]))
  end

  AutoScalingGroup('AutoScaleGroup') do
    UpdatePolicy('AutoScalingRollingUpdate', {
      "MinInstancesInService" => "0",
      "MaxBatchSize"          => "1",
      "SuspendProcesses"      => ["HealthCheck","ReplaceUnhealthy","AZRebalance","AlarmNotification","ScheduledActions"]
    })
    LaunchConfigurationName Ref('LaunchConfig')
    HealthCheckGracePeriod '500'
    MinSize Ref('AsgMin')
    MaxSize Ref('AsgMax')
    VPCZoneIdentifier az_conditional_resources('SubnetPublic', maximum_availability_zones)
    addTag("Name", FnJoin("",[Ref('EnvironmentName'), "-bastion-xx"]), true)
    addTag("Environment",Ref('EnvironmentName'), true)
    addTag("EnvironmentType", Ref('EnvironmentType'), true)
    addTag("Role", "bastion", true)
  end

  Output('SecurityGroupBastion', Ref('SecurityGroupBastion'))

end
