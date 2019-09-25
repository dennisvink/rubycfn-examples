=begin

Creating an S3 Bucket
=====================
We are going to use RubyCfn to create a couple of S3 buckets.
The first example is a bucket for which we don't set a name. AWS creates the name dynamically.
The second example is a bucket that we explicitly name. Note that this bucket name must be unique across AWS.
Our third example is a bucket where we specify an ammount. Rubycfn takes care of the resource creation.
In our final and 4th example we output the S3 Bucket name that AWS generated dynamically.
=end

# Example 1
resource :my_example_s3_bucket,
         type: "AWS::S3::Bucket"

# Example 2
resource :my_amazing_s3_bucket,
         type: "AWS::S3::Bucket" do |r|
  r.property(:bucket_name) { "some-unique-bucket-name" }
end

# Example 3
resource :my_outstanding_bucket,
         amount: 3,
         type: "AWS::S3::Bucket"

# Example 4
output :example_1_bucket_name,
       value: :my_example_s3_bucket.ref
