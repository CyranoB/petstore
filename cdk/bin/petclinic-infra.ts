#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import ec2 = require('@aws-cdk/aws-ec2');
import ecs = require('@aws-cdk/aws-ecs');
import rds = require('@aws-cdk/aws-rds');
import ssm = require('@aws-cdk/aws-ssm');
import ecr = require('@aws-cdk/aws-ecr');
import ecs_patterns = require('@aws-cdk/aws-ecs-patterns');
import { Tag } from '@aws-cdk/core';

export class AWSomePetClinicStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'petclinic-vpc', { maxAzs: 3, natGateways: 1 });

    const cluster = new ecs.Cluster(this, 'petclinic-cluster', { vpc });

    const dbSecurityGroup = new ec2.SecurityGroup(this, 'petclinic-db-sg', {
      vpc: vpc,
      description: "database security group"
    });

    dbSecurityGroup.addIngressRule(ec2.Peer.ipv4(ec2.Vpc.DEFAULT_CIDR_RANGE), ec2.Port.tcp(3306), "Allow inbound to db within VPC")

    const subnetGroup = new rds.CfnDBSubnetGroup(this, 'Subnet', {
      subnetIds: vpc.privateSubnets.map(privateSubnet => privateSubnet.subnetId),
      dbSubnetGroupDescription: 'Database subnet group',
    });


    const ssmdbpassword = ssm.StringParameter.valueForSecureStringParameter(this, '/petstore/dbpassword', 1);

    const dbCluster = new rds.CfnDBCluster(this, "PetClinicDBCluster", {
      engine: 'aurora',
      engineMode: 'serverless',
      databaseName: 'petstore',
      masterUsername: 'dbaadmin',
      masterUserPassword: ssmdbpassword,
      dbSubnetGroupName: subnetGroup.ref,
      vpcSecurityGroupIds: [dbSecurityGroup.securityGroupId],
      scalingConfiguration: {
        autoPause: true,
        minCapacity: 2,
        maxCapacity: 8,
        secondsUntilAutoPause: 600
      }
    });

    const dbHost = dbCluster.attrEndpointAddress;
    const dbPort = dbCluster.attrEndpointPort;
    const dbUrl = "jdbc:mysql://" + dbHost + ":" + dbPort + "/petstore";

    console.log('JDBC: ' + dbUrl);

    const ecrRepoArn = ssm.StringParameter.valueForStringParameter(this, '/petstore/ecr-repository-arn');
    const ecrRepoName = ssm.StringParameter.valueForStringParameter(this, '/petstore/ecr-repository-name');

    const ecrRepo = ecr.Repository.fromRepositoryAttributes(this, 'ecrRepo', {
      repositoryArn: ecrRepoArn,
      repositoryName: ecrRepoName
    });
    const dockerImage = ecs.ContainerImage.fromEcrRepository(ecrRepo);

    const loadBalancedFargateService = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'petclinic-fg-service', {
      cluster,
      memoryLimitMiB: 2048,
      cpu: 1024,
      taskImageOptions: {
        image: dockerImage,
        containerPort: 8080,
        enableLogging: true,
        environment: {
          'database': 'mysql',
          'spring.datasource.url': dbUrl,
          'spring.datasource.username': 'dbaadmin',
          'spring.datasource.initialization-mode': 'always'
        },
        secrets: {
          'spring.datasource.password': ecs.Secret.fromSsmParameter(ssm.StringParameter.fromSecureStringParameterAttributes(this, 'password',
            {
              parameterName: '/petstore/dbpassword',
              version:1
            }))
        }
      },
    });
  }
}

const app = new cdk.App();
const stack = new AWSomePetClinicStack(app, 'petclinic-stack');