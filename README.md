# awsMFA
TL:DR This is a Bash script to automate the management of MFA tokens for AWS, including the ability to use remote profiles.

As a security professional, I can't stand having tokens lying around that don't require multifactor authentication (MFA), so I set up all my AWS environments to require MFA for all actions (other than resetting MFA tokens).  This does make it harder to use the AWS CLI because standard token can't be used for anything except to retrieve temporary tokens based on supplying MFA.  The issue is further complicated if you access other accounts using roles.  This script makes all those scenarios very easy to manage.

## configuration
First you must supply "permanant" credentials for your primary account.  These are the normal key and secret tokens you can generate in your profile in AIM.  You'll need to configure them as the variables:

AWS_USERNAME="<userid>"
PERM_KEYID="<keyid>"
PERM_SECRET="<token>"
AWS_ACCOUNT_ID="<accountid>"

The PROFILES variable contains an array of Roles to configure into profules using the format:
PROFILES=("<profileName1> arn:aws:iam::<accountID1>:role/<RoleName1>"\
  "<profileName2> arn:aws:iam::<accountID2>:role/<RoleName2>"\
  "<profileName3> arn:aws:iam::<accountID3>:role/<RoleName3>")

The first time you should invoke the script with the "reset option" as:
awsMFA.sh reset

This will initialize your ~/.aws/credentials file with the [nomfa] profile and permanaent credentials so that the MFA tokens be generated.  This only needs to be done once unless you change your access tokens or if the file gets corrupted.

## invoking with MFA digits
Then you can invoke the script using the numbers from your TOTP:
```
awsMFA.sh 123456
setting profile default
setting profile profileName1
setting profile profileName2
setting profile profileName3
```
This will generate temporary credentials using the MFA and create a [default] profile using those temp credentials.  It will also iterate through each of your roles and create temporary credentials for those roles and store tham as the named profiles.

To use the default (main) profile, nothing needs to be done.  To use one of the other profiles set the AWS_PROFILE environment varialbe to one of your other profiles, or use the --profile switch to aws to indicate your profile:
```
aws s3 ls                         //uses the default profile
export AWS_PFOFILE=profileName2
aws s3 ls                         //uses profileName2
aws --profile profileName3 s3 ls  //uses profileName3
```

## updating the role profiles without new TOTP token
Unfortunately role-based profiles expire after an hour, where the main profile can last much longer.  So if you invoke the script without supplying an MFA token it will attempt to just renew the profile tokens:
```
awsMFA.sh 
setting profile profileName1
setting profile profileName2
setting profile profileName3
```

profit!
