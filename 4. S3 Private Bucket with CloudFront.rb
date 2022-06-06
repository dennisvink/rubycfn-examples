=begin

Creating a private S3 Bucket backed with CloudFront
===================================================
This code creates a CloudFormation stack with a private S3 bucket that is backed by CloudFront.
You can use it to host static web apps or web pages.
=end

resource :my_bucket,
         type: "AWS::S3::Bucket" do |r|
  r.property(:access_control) { "Private" }
end

resource :my_origin_access_identity,
         type: "AWS::CloudFront::CloudFrontOriginAccessIdentity" do |r|
  r.property(:cloud_front_origin_access_identity_config) do
    {
      "Comment": "Allows CloudFront to reach the bucket"
    }
  end
end

resource :my_bucket_policy,
         type: "AWS::S3::BucketPolicy" do |r|
  r.property(:bucket) { :my_bucket.ref }
  r.property(:policy_document) do
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "s3:GetObject*",
            "s3:GetBucket*",
            "s3:List*"
          ],
          "Effect": "Allow",
          "Principal": {
            "CanonicalUser": {
              "Fn::GetAtt": [
                "MyOriginAccessIdentity",
                "S3CanonicalUserId"
              ]
            }
          },
          "Resource": [
            :my_bucket.ref(:arn),
            "${MyBucket.Arn}/*".fnsub
          ]
        }
      ]
    }
  end
end
