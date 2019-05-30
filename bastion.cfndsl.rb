CloudFormation do

  Condition("SpotPriceSet", FnNot(FnEquals(Ref('SpotPrice'), '')))

  EC2_SecurityGroup('SecurityGroupBastion') do
    GroupDescription FnJoin(' ', [ Ref('EnvironmentName'), component_name ])
    VpcId Ref('VPCId')
    SecurityGroupIngress sg_create_rules(securityGroups, ip_blocks) if defined? securityGroups
    Metadata({
      cfn_nag: {
        rules_to_suppress: [
          { id: 'F1000', reason: 'ignore for now' }
        ]
      }
    })
  end

  EIP('BastionIPAddress') do
    Domain 'vpc'
  end

  RecordSet('BastionDNS') do
    HostedZoneName FnSub("#{dns_format}.")
    Comment 'Bastion Public Record Set'
    Name FnSub("#{instance_name}.#{dns_format}.")
    Type 'A'
    TTL 60
    ResourceRecords [ Ref("BastionIPAddress") ]
  end

  policies = []
  iam_policies.each do |name,policy|
    policies << iam_policy_allow(name,policy['action'],policy['resource'] || '*')
  end if defined? iam_policies

  Role('Role') do
    AssumeRolePolicyDocument service_role_assume_policy(iam_services)
    Path '/'
    Policies(policies)
    Metadata({
      cfn_nag: {
        rules_to_suppress: [
          { id: 'F3', reason: 'ignore describe* for now' }
        ]
      }
    })
  end

  InstanceProfile('InstanceProfile') do
    Path '/'
    Roles [Ref('Role')]
  end

  bastion_userdata = [
    "#!/bin/bash\n",
    "aws --region ", Ref("AWS::Region"), " ec2 associate-address --allocation-id ", FnGetAtt('BastionIPAddress','AllocationId') ," --instance-id $(curl http://169.254.169.254/2014-11-05/meta-data/instance-id -s)\n",
    "hostname ", Ref('EnvironmentName') ,"-" ,"bastion-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\n",
    "sed '/HOSTNAME/d' /etc/sysconfig/network > /tmp/network && mv -f /tmp/network /etc/sysconfig/network && echo \"HOSTNAME=", Ref('EnvironmentName') ,"-" ,"bastion-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\" >>/etc/sysconfig/network && /etc/init.d/network restart\n",
  ]

  bastion_userdata.push(*userdata.split("\n")) if defined? userdata

  LaunchConfiguration('LaunchConfig') do
    ImageId Ref('Ami')
    InstanceType Ref('InstanceType')
    AssociatePublicIpAddress true
    IamInstanceProfile Ref('InstanceProfile')
    KeyName Ref('KeyName')
    SpotPrice FnIf('SpotPriceSet', Ref('SpotPrice'), Ref('AWS::NoValue'))
    SecurityGroups [ Ref('SecurityGroupBastion') ]
    UserData FnBase64(FnJoin("",bastion_userdata))
  end

  instance_tags = {}
  instance_tags["Name"] = FnJoin("",[Ref('EnvironmentName'), "-#{instance_name}-xx"])
  instance_tags["Environment"] = Ref('EnvironmentName')
  instance_tags["EnvironmentName"] = Ref('EnvironmentName')
  instance_tags["EnvironmentType"] = Ref('EnvironmentType')
  instance_tags["Role"] = "bastion"
  tags.each { |k,v| instance_tags[k] = v } if defined? tags and tags.any?

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
    VPCZoneIdentifier Ref('SubnetIds')
    instance_tags.each { |k,v| addTag(k,v,true) }
  end

  Output('SecurityGroupBastion', Ref('SecurityGroupBastion'))

end
