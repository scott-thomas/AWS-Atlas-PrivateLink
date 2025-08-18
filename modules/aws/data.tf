resource "null_resource" "build_lambda_assets" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/function/dist
      cp -r ${path.module}/function/*.py ${path.module}/function/dist/
      pip install -r ${path.module}/function/requirements.txt -t ${path.module}/function/dist/
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    always_run = timestamp()
  }
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function/dist" # Directory containing lambda_function.py and installed pymongo
  output_path = "${path.module}/function/lambda_function.zip" # Output zip file path
  depends_on  = [null_resource.build_lambda_assets]
}