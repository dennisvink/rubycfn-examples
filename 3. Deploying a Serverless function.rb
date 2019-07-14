=begin

Creating a Serverless function
==============================
For this example we are deploying an API Gateway-backed serverless function using RubyCfn.
=end

# Enable CloudFormation Transformations
transform

# Allow dynamic configuration of Lambda bucket name.
# e.g.: export LAMBDA_BUCKET=my_bucket
variable :lambda_bucket,
         value: ENV["LAMBDA_BUCKET"]

# Create a Serverless Lambda function backed by API Gateway
resource :my_serverless_function,
         type: "AWS::Serverless::Function" do |r|
  r.property(:handler) { "index.lambda_handler" }
  r.property(:runtime) { "nodejs10.x" }
  r.property(:code_uri) { "s3://#{lambda_bucket}/lambda_function.zip" }
  r.property(:description) { "My Serverless Lambda Function" }
  r.property(:timeout) { 30 }
  r.property(:events) do
    {
      "compiler": {
        "Type": "Api",
        "Properties": {
          "Path": "/",
          "Method": "post"
        }
      }
    }
  end
end
