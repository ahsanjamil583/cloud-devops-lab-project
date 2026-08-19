resource "terraform_data" "backend_validation" {
  input = {
    project = "cloud-devops-lab-project"
    phase   = "2"
    backend = "s3"
  }
}
