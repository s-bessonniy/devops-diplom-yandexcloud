terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "diplom-backet"
    region = "ru-central1"
    key = "diplom-backet/terraform.tfstate"
    
   
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true 

  }
}
